# U-Boot

## Current version used

- U-Boot: `2026.04`

## What it does

- Builds U-Boot from `u-boot/`
- Starts from `ikr_defconfig`
- Applies extra config toggles required by this project (virtio + board/ISA settings)
- Produces `u-boot.bin` used later by disk/payload scripts

## Prerequisite variables

Exported by `scripts/setup-env.sh` (source it first):
- `ROOT_DIR` — repo root
- `ARCH` — target arch (`riscv`)
- `CROSS_COMPILE` — toolchain prefix

## How to run

```bash
source scripts/setup-env.sh
./scripts/build_uboot.sh
```

## Config base and overrides

- Base defconfig: `u-boot/configs/ikr_defconfig`
- Script enables:
  - `DEBUG_SBI_CONSOLE`
  - `VIRTIO_MMIO`
  - `VIRTIO_BLK`
  - `CMD_VIRTIO`
  - `OF_BOARD`
- Script disables:
  - `RISCV_ISA_C`
  - `RISCV_ISA_F`
  - `RISCV_ISA_D`

## Output

- Main binary: `u-boot/u-boot.bin`
