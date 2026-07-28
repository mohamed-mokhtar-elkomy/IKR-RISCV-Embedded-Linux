# Rootfs (BusyBox initramfs)

## What it does

- Builds a static BusyBox using `configs/busybox/ikr.config` (merged on top
  of `allnoconfig`)
- Installs it and writes a custom `/init` script (mounts `/proc`, `/sys`,
  creates the IKR uart device node, spawns `ash`)
- Packs everything into a compressed cpio initramfs

## Tools included in this rootfs

BusyBox applets enabled by `configs/busybox/ikr.config`:
- `init`
- `ash` (`sh` points to `ash`)
- `mount`
- `mkdir`
- `echo`
- `cat`
- `dmesg`
- `grep`
- `ls`
- `setsid`
- `sleep`
- `cttyhack`
- `stty`
- `getty`
- `mknod`
- `awk`
- `test`

## Prerequisites

Exported by `scripts/setup-env.sh` — source it before running:
- `ROOT_DIR` — repo root
- `OUTPUT_DIR` — where `initramfs.cpio.gz` is written
- `ARCH` — target arch (`riscv`)
- `CROSS_COMPILE` — cross-compiler prefix; must match a toolchain already
  built in `riscv64-unknown-linux-musl/` or `riscv64-unknown-linux-gnu/`

## How to run

```bash
source scripts/setup-env.sh
./scripts/build_rootfs.sh
```

## Output

- `output/initramfs.cpio.gz`
