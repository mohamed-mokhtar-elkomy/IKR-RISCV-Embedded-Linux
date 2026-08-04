#!/usr/bin/env bash
set -euo pipefail

# SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# source "${SCRIPT_DIR}/setup-env.sh"

OPENSBI_SRC_DIR="${ROOT_DIR}/opensbi"

dtc -I dts -O dtb -o "${OUTPUT_DIR}/ikr.dtb" "${ROOT_DIR}/device-tree/ikr.dts"

if [[ ! -d "${OPENSBI_SRC_DIR}" ]]; then
    echo "Error: opensbi source directory not found at: ${OPENSBI_SRC_DIR}" >&2
    exit 1
fi

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "Error: disk image not found at: ${DISK_IMAGE}" >&2
    echo "Run scripts/build_disk_image.sh first." >&2
    exit 1
fi

cd "${OPENSBI_SRC_DIR}"
make -j"$(nproc)" \
    PLATFORM=ikr \
    CROSS_COMPILE="${CROSS_COMPILE}" \
    FW_FDT_PATH="${OUTPUT_DIR}/ikr.dtb" \
    FW_PAYLOAD_PATH="${DISK_IMAGE}"

FINAL_PAYLOAD="${OPENSBI_SRC_DIR}/build/platform/ikr/firmware/fw_payload.bin"
cp -f "${FINAL_PAYLOAD}" "${OUTPUT_DIR}/fw_payload.bin"

echo "OpenSBI build complete."
echo "Source path: ${OPENSBI_SRC_DIR}"
echo "Disk image payload: ${DISK_IMAGE}"
echo "Final fw_payload.bin: ${FINAL_PAYLOAD}"
echo "Copied to: ${OUTPUT_DIR}/fw_payload.bin"