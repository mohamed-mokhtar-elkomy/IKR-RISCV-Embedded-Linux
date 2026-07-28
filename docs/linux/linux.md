# Linux kernel

## What it does

- Builds Linux for RISC-V from `linux/`
- Uses base config fragment: `configs/linux/ikr.config`
- Optional embedded-rootfs build also uses: `configs/linux/ikr-rootfs.config`
- Writes kernel image to `output/Image`

## Prerequisite variables

Exported by `scripts/setup-env.sh` (source it first):
- `ROOT_DIR` — repo root
- `OUTPUT_DIR` — output folder
- `ARCH` — target arch (`riscv`)
- `CROSS_COMPILE` — toolchain prefix
- `DEFCONFIG` (optional) — kernel base defconfig (default: `defconfig`)

## Build (kernel only)

```bash
source scripts/setup-env.sh
./scripts/build_linux.sh
```

- Config path used by script: `configs/linux/ikr.config`
- Output: `output/Image`

## Build (kernel + embedded rootfs)

```bash
source scripts/setup-env.sh
./scripts/build_linux_embedded_rootfs.sh
```

- Requires existing rootfs archive: `output/initramfs.cpio.gz`
- If missing, build it first:

```bash
source scripts/setup-env.sh
./scripts/build_rootfs.sh
```

- Config fragments used:
  - `configs/linux/ikr.config`
  - `configs/linux/ikr-rootfs.config`
- Script also sets `CONFIG_INITRAMFS_SOURCE` to `output/initramfs.cpio.gz`
- Output: `output/Image`
