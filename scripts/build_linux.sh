#!/usr/bin/env bash
set -euo pipefail

# SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# source "${SCRIPT_DIR}/setup-env.sh"

KERNEL_SRC_DIR="${ROOT_DIR}/linux"
DEFCONFIG="${DEFCONFIG:-defconfig}"
KERNEL_IMAGE_PATH="${KERNEL_SRC_DIR}/arch/${ARCH}/boot/Image"
CONFIG_FRAGMENT="${ROOT_DIR}/configs/linux/ikr.config"

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

cd "${KERNEL_SRC_DIR}"

make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" "${DEFCONFIG}"

# Requested kernel configuration customizations.
scripts/kconfig/merge_config.sh -m .config "${CONFIG_FRAGMENT}"

make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" olddefconfig
make -j$(nproc) ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}"

if [[ ! -f "${KERNEL_IMAGE_PATH}" ]]; then
	echo "Error: kernel image not found at: ${KERNEL_IMAGE_PATH}" >&2
	exit 1
fi

cp -f "${KERNEL_IMAGE_PATH}" "${OUTPUT_DIR}/Image"

echo "Kernel build complete."
echo "Kernel source path: ${KERNEL_SRC_DIR}"
echo "Config file: ${KERNEL_SRC_DIR}/.config"
echo "Kernel image output: ${OUTPUT_DIR}/Image"