# OpenSBI

## Current version used

- OpenSBI: `1.8`

## What it does

- Builds OpenSBI from `opensbi/` for platform `ikr`
- Compiles device tree: `device-tree/ikr.dts` -> `ikr.dtb`
- Uses `output/disk.img` as `FW_PAYLOAD_PATH` (payload input)
- Produces `fw_payload.bin` and copies it to `output/fw_payload.bin`

## Prerequisite variables

Exported by `scripts/setup-env.sh` (source it first):
- `ROOT_DIR` — repo root
- `OUTPUT_DIR` — output folder
- `CROSS_COMPILE` — toolchain prefix
- `DISK_IMAGE` — expected payload image path (`output/disk.img`)

## Input files required before build

- `output/disk.img` (build disk image first)
- `device-tree/ikr.dts`

## How to run

```bash
source scripts/setup-env.sh
./scripts/build_opensbi_payload.sh
```

## Build flags used

- `PLATFORM=ikr`
- `CROSS_COMPILE=${CROSS_COMPILE}`
- `FW_FDT_PATH=ikr.dtb`
- `FW_PAYLOAD_PATH=output/disk.img`

## Output

- Generated DTB: `ikr.dtb`
- OpenSBI payload copy: `output/fw_payload.bin`
- Upstream build artifact: `opensbi/build/platform/ikr/firmware/fw_payload.bin`
