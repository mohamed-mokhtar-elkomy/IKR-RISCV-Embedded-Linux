#!/usr/bin/env bash
set -euo pipefail

export TOOLCHAIN_LIBC=glibc
source "${SCRIPT_DIR}/setup-env.sh"

TOOLCHAIN_SRC_DIR="${ROOT_DIR}/riscv-gnu-toolchain"

if [[ ! -d "${TOOLCHAIN_SRC_DIR}" ]]; then
    echo "Error: riscv-gnu-toolchain source directory not found at: ${TOOLCHAIN_SRC_DIR}" >&2
    exit 1
fi

cd "${TOOLCHAIN_SRC_DIR}"
if [[ -d "${TOOLCHAIN_DIR}" ]]; then
    rm -rf "${TOOLCHAIN_DIR}"
fi
mkdir -p "${TOOLCHAIN_DIR}"

./configure \
    --prefix="${TOOLCHAIN_DIR}" \
    --with-arch=rv64ima_zicsr_zifencei \
    --with-abi=lp64 \
    --with-languages=c,c++ \
    --disable-multilib

# The install dir was wiped above, so drop the stamps/ and build-* dirs of any
# previous run; otherwise make skips steps whose output no longer exists.
make clean

# The gprofng copy bundled with gdb does not build against host glibc >= 2.43
# (strstr & co. became _Generic macros); it is a host profiler we don't need.
make -j$(nproc) GDB_TARGET_FLAGS_EXTRA=--disable-gprofng linux

echo "Toolchain build complete."
echo "Install path: ${TOOLCHAIN_DIR}"
echo "Add to PATH: export PATH=${TOOLCHAIN_DIR}/bin:\$PATH"
