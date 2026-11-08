#!/usr/bin/env bash
set -euo pipefail

BUSYBOX_SRC_DIR="${ROOT_DIR}/busybox"
CONFIG_FRAGMENT="${ROOT_DIR}/configs/busybox/ikr.config"

if [[ ! -d "${BUSYBOX_SRC_DIR}" ]]; then
	echo "Error: BusyBox source directory not found at: ${BUSYBOX_SRC_DIR}" >&2
	exit 1
fi

if [[ ! -f "${CONFIG_FRAGMENT}" ]]; then
	echo "Error: BusyBox config fragment not found at: ${CONFIG_FRAGMENT}" >&2
	exit 1
fi

cd "${BUSYBOX_SRC_DIR}"
rm -rf _install ### TODO remove it later because we will run clean befoe this script in the makefile

# Step 1: generate an all-no base
make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" allnoconfig

# Step 2: patch .config with sed (BusyBox's own recommended workflow — see
# scripts/kconfig/Makefile line 22).  KCONFIG_ALLCONFIG works for strings but
# silently forces booleans back to n, so sed is more reliable for bools.
# BusyBox ships no merge_config.sh (unlike the Linux kernel), so the fragment
# file is applied line-by-line here instead.
_bb_enable() { sed -i "s|^# CONFIG_${1} is not set|CONFIG_${1}=y|" .config; }
_bb_set_str() { sed -i "s|^CONFIG_${1}=.*|CONFIG_${1}=\"${2}\"|" .config; }

while IFS= read -r line; do
	[[ -z "${line}" || "${line}" == \#* ]] && continue
	cfg="${line%%=*}"
	val="${line#*=}"
	[[ "${val}" == "y" ]] && _bb_enable "${cfg#CONFIG_}"
done < "${CONFIG_FRAGMENT}"

# CROSS_COMPILER_PREFIX depends on the workspace's CROSS_COMPILE value, so it
# cannot live in a static config fragment.
_bb_set_str CROSS_COMPILER_PREFIX "${CROSS_COMPILE}"


make -j"$(nproc)" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" CFLAGS_busybox="-static"
make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" CONFIG_PREFIX="${BUSYBOX_SRC_DIR}/_install" install

mkdir -p "${BUSYBOX_SRC_DIR}/_install"/{proc,sys,dev}

# Cross-compile every apps/<name>.c into /usr/bin/<name> on the target.
# Linked statically, so the rootfs does not need the libc shared libraries.
APPS_DIR="${ROOT_DIR}/apps"
shopt -s nullglob
for src in "${APPS_DIR}"/*.c; do
	app="$(basename "${src}" .c)"
	"${CROSS_COMPILE}gcc" ${ARCH_FLAGS} -O2 -static -o "${BUSYBOX_SRC_DIR}/_install/usr/bin/${app}" "${src}"
	echo "Built app: /usr/bin/${app}"
done
shopt -u nullglob

# Create init directly in the installed rootfs.
cat > "${BUSYBOX_SRC_DIR}/_install/init" <<'EOF'
#!/bin/sh
mount -t proc  none /proc
mount -t sysfs none /sys

# Find the IKR uart's dynamic major from /proc/tty/drivers and create
# the device node manually (no devtmpfs is mounted — see initramfs spec
# below for why).  Fall back to 242 (the major dynamically allocated by
# the kernel on this build) if parsing fails.
maj=$(awk '/\/dev\/ttyIKR/ {print $3; exit}' /proc/tty/drivers)
: "${maj:=242}"
mknod -m 660 /dev/ttyIKR0 c "$maj" 0

# Bind stdio to the IKR uart so the shell prompt and user-space output
# go through the tty layer (and not through printk via /dev/console).
exec 0</dev/ttyIKR0
exec 1>/dev/ttyIKR0
exec 2>/dev/ttyIKR0

# The kernel tty layer's own line-discipline echo stays enabled by default
# on this tty; BusyBox ash's line editor (FEATURE_EDITING) echoes typed
# characters itself, so leaving kernel ECHO on doubles every keystroke and
# reprints the whole command line a second time after Enter. Explicitly
# disable it once here so ash's own echo is the only one active.
stty -echo

# Static prompt showing the (only) user before the hash. ASH_EXPAND_PRMT /
# FEATURE_EDITING are not enabled in this minimal build, so ash does not
# interpret bash-style \u \h \w prompt escapes — use a plain literal string
# instead of relying on them.
export USER=root
export HOME=/root
export PS1='root@ikr# '

cat <<'BANNER'

============================================
  Welcome to IKR RV64 Embedded Linux
  Soft-Core RISC-V on Intel Cyclone 10 GX
============================================

BANNER

# PID 1 cannot become a session leader, so spawn the interactive shell
# in a child via setsid+cttyhack which gives it a controlling tty.
while :; do
    setsid -c cttyhack /bin/ash -i
    sleep 2
done
EOF
chmod 0755 "${BUSYBOX_SRC_DIR}/_install/init"

# mkdir -p "${BUSYBOX_SRC_DIR}/_install/etc"

# cat > "${BUSYBOX_SRC_DIR}/_install/etc/inittab" <<'EOF'
# # /etc/inittab

# # Run this before anything else
# ::sysinit:/bin/echo "BusyBox init taking over..."

# # Explicitly bind the shell to the console
# console::askfirst:-/bin/sh
# EOF

# Pack the installed rootfs into a compressed initramfs archive.
# gen_init_cpio is used instead of find|cpio because it can create device
# nodes (nod entries) without root — mknod requires root but gen_init_cpio
# writes them directly into the cpio stream.
SPEC="${OUTPUT_DIR}/initramfs.txt"
{
    echo "# auto-generated initramfs spec"
    # /dev directory must be declared before /dev/console
    echo "dir  /dev          0755 0 0"
    # Static device nodes — we do NOT mount devtmpfs (kernel may not have
    # CONFIG_DEVTMPFS_MOUNT, and even when it does, mounting devtmpfs over
    # /dev would shadow these nodes for any process whose stdio was opened
    # against the cpio /dev/console before the mount).
    echo "nod  /dev/console  0600 0 0 c 5 1"
    echo "nod  /dev/null     0666 0 0 c 1 3"
    echo "nod  /dev/zero     0666 0 0 c 1 5"
    echo "nod  /dev/tty      0666 0 0 c 5 0"
    echo "nod  /dev/kmsg     0644 0 0 c 1 11"
    # Match major/minor of the IKR uart driver (TTY_MAJOR=4 not used; the
    # ikr_uart driver uses dynamically-allocated major.  Using devtmpfs
    # would handle this automatically; without it, /dev/ttyIKR0 must be
    # created by the init script via mknod once the major is known.
    # cttyhack reads /sys/class/tty/console/active and opens /dev/<name>,
    # so init creates the node from sysfs info before spawning the shell.
    (cd "${BUSYBOX_SRC_DIR}/_install" && find . ! -name . -printf '%P\n') | while IFS= read -r rel; do
        # /dev is already declared via the nod entry above
        [[ "/${rel}" == /dev ]] && continue
        src="${BUSYBOX_SRC_DIR}/_install/${rel}"
        if [[ -L "${src}" ]]; then
            echo "slink /${rel} $(readlink "${src}") 0777 0 0"
        elif [[ -d "${src}" ]]; then
            echo "dir  /${rel} 0755 0 0"
        elif [[ -x "${src}" ]]; then
            echo "file /${rel} ${src} 0755 0 0"
        else
            echo "file /${rel} ${src} 0644 0 0"
        fi
    done
} > "${SPEC}"

# gen_init_cpio is normally built as a kernel host-tool, but this script can
# run standalone before the kernel has been configured/built. It has no
# kernel-header dependencies, so compile it directly if missing.
GEN_INIT_CPIO="${ROOT_DIR}/linux/usr/gen_init_cpio"
if [[ ! -x "${GEN_INIT_CPIO}" ]]; then
    cc -O2 -o "${GEN_INIT_CPIO}" "${ROOT_DIR}/linux/usr/gen_init_cpio.c"
fi

"${GEN_INIT_CPIO}" "${SPEC}" | gzip -9 > "${OUTPUT_DIR}/initramfs.cpio.gz"

echo "BusyBox build complete."
echo "Source path: ${BUSYBOX_SRC_DIR}"
echo "Install path: ${BUSYBOX_SRC_DIR}/_install"
echo "Initramfs output: ${OUTPUT_DIR}/initramfs.cpio.gz"
