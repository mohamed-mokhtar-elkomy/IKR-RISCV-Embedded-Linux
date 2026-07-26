#!/usr/bin/env bash
set -euo pipefail

KERNEL_SRC_DIR="${ROOT_DIR}/linux"
DEFCONFIG="${DEFCONFIG:-defconfig}"
INITRAMFS_SOURCE="${OUTPUT_DIR}/initramfs.cpio.gz"
KERNEL_IMAGE_PATH="${KERNEL_SRC_DIR}/arch/${ARCH}/boot/Image"
CONFIG_FRAGMENT="${ROOT_DIR}/configs/linux/ikr.config"
ROOTFS_CONFIG_FRAGMENT="${ROOT_DIR}/configs/linux/ikr-rootfs.config"

if [[ ! -d "${KERNEL_SRC_DIR}" ]]; then
    echo "Error: linux source directory not found at: ${KERNEL_SRC_DIR}" >&2
    exit 1
fi

if [[ ! -x "${KERNEL_SRC_DIR}/scripts/config" ]]; then
    echo "Error: kernel config helper not found: ${KERNEL_SRC_DIR}/scripts/config" >&2
    exit 1
fi

if [[ ! -f "${CONFIG_FRAGMENT}" ]]; then
    echo "Error: kernel config fragment not found at: ${CONFIG_FRAGMENT}" >&2
    exit 1
fi

if [[ ! -f "${ROOTFS_CONFIG_FRAGMENT}" ]]; then
    echo "Error: kernel config fragment not found at: ${ROOTFS_CONFIG_FRAGMENT}" >&2
    exit 1
fi

if [[ ! -f "${INITRAMFS_SOURCE}" ]]; then
    echo "Error: initramfs archive not found at: ${INITRAMFS_SOURCE}" >&2
    echo "Run scripts/build_rootfs.sh first." >&2
    exit 1
fi

cd "${KERNEL_SRC_DIR}"

make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" "${DEFCONFIG}"

scripts/kconfig/merge_config.sh -m .config "${CONFIG_FRAGMENT}" "${ROOTFS_CONFIG_FRAGMENT}"

# INITRAMFS_SOURCE holds an absolute path that depends on the workspace
# location, so it cannot live in a static config fragment.
scripts/config --file .config --set-str INITRAMFS_SOURCE "${INITRAMFS_SOURCE}"

make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" olddefconfig
make -j"$(nproc)" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}"

if [[ ! -f "${KERNEL_IMAGE_PATH}" ]]; then
    echo "Error: kernel image not found at: ${KERNEL_IMAGE_PATH}" >&2
    exit 1
fi

cp -f "${KERNEL_IMAGE_PATH}" "${OUTPUT_DIR}/Image"

echo "Kernel build complete with embedded initramfs."
echo "Kernel source path: ${KERNEL_SRC_DIR}"
echo "Config file: ${KERNEL_SRC_DIR}/.config"
echo "Initramfs archive: ${INITRAMFS_SOURCE}"
echo "Kernel image output: ${OUTPUT_DIR}/Image"



