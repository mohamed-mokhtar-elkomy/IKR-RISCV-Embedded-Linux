
#!/usr/bin/env bash
set -euo pipefail

UBOOT_SRC_DIR="${ROOT_DIR}/u-boot"
DEFCONFIG="ikr_defconfig"

if [[ ! -d "${UBOOT_SRC_DIR}" ]]; then
	echo "Error: u-boot source directory not found at: ${UBOOT_SRC_DIR}" >&2
	exit 1
fi

cd "${UBOOT_SRC_DIR}"

make "${DEFCONFIG}"
./scripts/config --enable DEBUG_SBI_CONSOLE
./scripts/config --enable VIRTIO_MMIO
./scripts/config --enable VIRTIO_BLK
./scripts/config --enable CMD_VIRTIO
./scripts/config --enable OF_BOARD # Use the prior-stage/OpenSBI provided DT at runtime
./scripts/config --disable RISCV_ISA_C
./scripts/config --disable RISCV_ISA_F
./scripts/config --disable RISCV_ISA_D
make olddefconfig
make -j"$(nproc)"

if [[ ! -f "${UBOOT_SRC_DIR}/u-boot.bin" ]]; then
	echo "Error: u-boot.bin not found at: ${UBOOT_SRC_DIR}/u-boot.bin" >&2
	exit 1
fi

cp -f "${UBOOT_SRC_DIR}/u-boot.bin" "${OUTPUT_DIR}/u-boot.bin"

echo "U-Boot build complete."
echo "U-Boot source path: ${UBOOT_SRC_DIR}"
echo "Defconfig used: ${DEFCONFIG}"
echo "U-Boot binary output: ${OUTPUT_DIR}/u-boot.bin"