#!/usr/bin/env bash
# Setup environment variables for the build system

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
export ROOT_DIR
export OUTPUT_DIR="${ROOT_DIR}/output"
mkdir -p "${OUTPUT_DIR}"

export UBOOT_BIN="${ROOT_DIR}/u-boot/u-boot.bin"
export KERNEL_IMAGE="${ROOT_DIR}/linux/arch/riscv/boot/Image"
export DISK_IMAGE="${OUTPUT_DIR}/disk.img"

export TARGET=riscv64-unknown-linux-musl
# export TARGET=riscv64-unknown-linux-gnuc
export ARCH_FLAGS="-march=rv64ima_zicsr_zifencei -mabi=lp64"
export TOOLCHAIN_DIR="${ROOT_DIR}/${TARGET}"
export PREFIX="${TOOLCHAIN_DIR}"

export PATH="${TOOLCHAIN_DIR}/bin:${PATH}"

# Set cross-compiler prefix.
export CROSS_COMPILE="riscv64-unknown-linux-musl-"
# export CROSS_COMPILE="riscv64-unknown-linux-gnu-"
export ARCH="riscv"