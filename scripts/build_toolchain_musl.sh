#!/usr/bin/env bash
set -euo pipefail

export TOOLCHAIN_LIBC=musl
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

# --with-arch=rv64ima \

./configure \
    --prefix="${TOOLCHAIN_DIR}" \
    --with-arch=rv64ima_zicsr_zifencei \
    --with-abi=lp64 \
    --enable-languages=c,c++ \
    --disable-bootstrap \
    --disable-multilib

make -j$(nproc) musl

echo "Toolchain build complete."
echo "Install path: ${TOOLCHAIN_DIR}"
echo "Add to PATH: export PATH=${TOOLCHAIN_DIR}/bin:\$PATH"
