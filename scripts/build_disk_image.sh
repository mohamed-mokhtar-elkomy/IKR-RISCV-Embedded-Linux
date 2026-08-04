#!/usr/bin/env bash
set -euo pipefail

# SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# source "${SCRIPT_DIR}/setup-env.sh"

KERNEL_OFFSET_HEX="0x1e00000"
KERNEL_OFFSET_DEC=$((KERNEL_OFFSET_HEX))

if [[ ! -f "${UBOOT_BIN}" ]]; then
    echo "Error: U-Boot binary not found at: ${UBOOT_BIN}" >&2
    exit 1
fi

if [[ ! -f "${KERNEL_IMAGE}" ]]; then
    echo "Error: Linux Image not found at: ${KERNEL_IMAGE}" >&2
    exit 1
fi

# Disk layout: U-Boot at offset 0, kernel Image at offset KERNEL_OFFSET_DEC.
# Image base is 0x40200000, so placing the kernel at offset 0x1e00000
# lands it at 0x42000000 where U-Boot expects kernel_addr_r.
truncate -s 0 "${DISK_IMAGE}"
dd if="${UBOOT_BIN}" of="${DISK_IMAGE}" conv=notrunc status=none
dd if="${KERNEL_IMAGE}" of="${DISK_IMAGE}" bs=1 seek="${KERNEL_OFFSET_DEC}" conv=notrunc status=none

echo "Disk image build complete."
echo "U-Boot binary: ${UBOOT_BIN}"
echo "Kernel image: ${KERNEL_IMAGE}"
echo "Disk image: ${DISK_IMAGE}"
