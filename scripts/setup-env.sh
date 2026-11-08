#!/usr/bin/env bash
# Setup environment variables for the build system

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
export ROOT_DIR
export OUTPUT_DIR="${ROOT_DIR}/output"
mkdir -p "${OUTPUT_DIR}"

export UBOOT_BIN="${OUTPUT_DIR}/u-boot.bin"
export KERNEL_IMAGE="${OUTPUT_DIR}/Image"
export DISK_IMAGE="${OUTPUT_DIR}/disk.img"

# Select the C library: musl (default) or glibc.
# Override with: make <target> TOOLCHAIN_LIBC=glibc
export TOOLCHAIN_LIBC="${TOOLCHAIN_LIBC:-musl}"
case "${TOOLCHAIN_LIBC}" in
    musl)  export TARGET=riscv64-unknown-linux-musl ;;
    glibc) export TARGET=riscv64-unknown-linux-gnu ;;
    *)
        echo "Error: unsupported TOOLCHAIN_LIBC='${TOOLCHAIN_LIBC}' (expected musl or glibc)" >&2
        return 1 2>/dev/null || exit 1
        ;;
esac

export ARCH_FLAGS="-march=rv64ima_zicsr_zifencei -mabi=lp64"
export TOOLCHAIN_DIR="${ROOT_DIR}/${TARGET}"
export PREFIX="${TOOLCHAIN_DIR}"

export PATH="${TOOLCHAIN_DIR}/bin:${PATH}"

# Set cross-compiler prefix.
export CROSS_COMPILE="${TARGET}-"
export ARCH="riscv"