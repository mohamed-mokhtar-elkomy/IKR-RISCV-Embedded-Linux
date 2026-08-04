# RISC-V Embedded Linux Build System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Version](https://img.shields.io/badge/version-1.0.0-blue)

**By:** Mohamed Elkomy, IKR Institute, Stuttgart University

## Overview

A comprehensive embedded Linux build system for RISC-V architecture with custom OpenSBI platform support. This project integrates the complete toolchain, bootloader, kernel, and firmware for building IKR RISC-V embedded Linux systems.

## Features

- **Complete RISC-V Toolchain Integration** - Pre-configured and automated toolchain setup
- **OpenSBI Firmware** - OpenSBI with custom platform implementation
- **U-Boot Bootloader** - Full bootloader integration and configuration
- **Linux Kernel** - Optimized kernel configurations for RISC-V targets
- **Custom Platform Support** - Professional custom RISC-V platform development
- **Automated Build System** - Simple make-based build process
- **Comprehensive Documentation** - Complete guides and configuration documentation
- **Reproducible Builds** - Git submodules ensure consistent builds

## Component Versions

This system uses the following component versions:

| Component | Version | Details |
|-----------|---------|---------|
| **Linux Kernel** | 7.0 | Custom IKR UART driver support |
| **U-Boot** | 2026.04 | Bootloader with IKR platform |
| **OpenSBI** | 1.8.1 | M-mode firmware with custom IKR platform |
| **BusyBox** | 1.37.0 | Minimal root filesystem |
| **RISC-V GNU Toolchain** | 2026.04.05 | Cross-compiler (musl/glibc) |
| **rvemu** | Latest | RISC-V emulator (included) |

**Note**: All components are tracked via git submodules to ensure reproducible builds.

## Prerequisites

Before building the system, ensure you have the following dependencies installed on your Debian/Ubuntu host system:

### One-Time Install (All Prerequisites)

```bash
sudo apt update && sudo apt install -y \
    git curl wget \
    build-essential gcc g++ make \
    autoconf automake autotools-dev libtool bison flex \
    texinfo gawk gperf patchutils \
    python3 python3-pip python3-toml python3-setuptools \
    bc file cpio rsync \
    libssl-dev libelf-dev pkg-config \
    libmpc-dev libmpfr-dev libgmp-dev libexpat-dev \
    zlib1g-dev libslirp-dev libncurses-dev \
    ninja-build cmake libglib2.0-dev \
    swig pahole device-tree-compiler
```

### System Requirements

- **OS**: Debian/Ubuntu Linux (tested on Ubuntu 20.04+)
- **Disk Space**: ~70GB for complete build
- **RAM**: 8GB minimum, 16GB recommended
- **Build Time**: 1-3 hours depending on your system (toolchain takes the longest)

For detailed component-specific prerequisites, see [docs/PREREQUISITES.md](docs/PREREQUISITES.md).

## Quick Start

### 1. Clone and Initialize

```bash
git clone <repository-url>
cd rp-workspace
git submodule update --init --recursive
```

This initializes all git submodules (Linux, U-Boot, OpenSBI, toolchain, etc.).

### 2. Build the Toolchain

First, build the RISC-V cross-compiler toolchain (musl libc - recommended):

```bash
make build-toolchain-musl
```

**Note**: This step takes 30-60 minutes. The toolchain will be installed to `riscv64-unknown-linux-musl/`.

For glibc instead of musl (see [docs/toolchain/toolchain.md](docs/toolchain/toolchain.md) for differences):
```bash
make build-toolchain-glibc
```

### 3. Build the Complete OS

Build all components (rootfs, Linux kernel with embedded initramfs, U-Boot, and OpenSBI payload):

```bash
make build-os
```

This is equivalent to running:
```bash
make build-rootfs                  # Build BusyBox-based root filesystem
make build-linux-embedded-rootfs   # Build Linux kernel with embedded initramfs
make build-uboot                   # Build U-Boot bootloader
make build-disk-image              # Create disk image with U-Boot and kernel
make build-opensbi-payload         # Build OpenSBI with embedded U-Boot+Linux
```

The final bootable image will be at `output/fw_payload.bin`.

### 4. Run on rvemu

Run the built system using the RISC-V emulator included in this project:

```bash
make run-rvemu
```

Or manually:
```bash
rvemu/target/release/rvemu-cli -k output/fw_payload.bin
```

**Note**: Press `Ctrl+C` to exit the emulator.

## Expected Output

When the system boots successfully, you should see:
1. OpenSBI banner and initialization
2. U-Boot boot messages
3. Linux kernel boot log
4. BusyBox login prompt

Sample output:
```
OpenSBI v1.x
[...]
U-Boot 2024.x
[...]
Starting kernel ...
[    0.000000] Linux version 6.x.x
[...]
Please press Enter to activate this console.
root@ikr#
```

## Project Structure

```
rp-workspace/
├── busybox/                    # BusyBox source and rootfs build artifacts
├── configs/                    # Configuration files for all components
│   ├── busybox/               # BusyBox configurations
│   ├── linux/                 # Linux kernel configurations
│   ├── opensbi/               # OpenSBI platform configs
│   └── uboot/                 # U-Boot configurations
├── device-tree/               # Device tree sources (.dts files)
├── docs/                      # Comprehensive documentation
│   ├── PREREQUISITES.md       # Detailed prerequisites by component
│   ├── linux/                 # Linux kernel documentation
│   ├── opensbi/              # OpenSBI documentation
│   └── u-boot/               # U-Boot documentation
├── linux/                     # Linux kernel source (submodule)
├── opensbi/                   # OpenSBI firmware source (submodule)
├── u-boot/                    # U-Boot bootloader source (submodule)
├── riscv-gnu-toolchain/       # RISC-V toolchain source (submodule)
├── riscv64-unknown-linux-musl/  # Built musl toolchain (after build)
├── riscv64-unknown-linux-gnu/   # Built glibc toolchain (after build)
├── rvemu/                     # RISC-V emulator for testing
├── qemu/                      # QEMU emulator (optional)
├── scripts/                   # Build automation scripts
│   ├── build_toolchain_musl.sh
│   ├── build_linux.sh
│   ├── build_opensbi.sh
│   ├── build_uboot.sh
│   └── ...
├── output/                    # Final build artifacts
│   ├── fw_payload.bin         # Bootable OpenSBI+U-Boot+Linux image
│   ├── fw_payload.vmf         # Flash image for hardware
│   └── ...
├── tools/                     # Utility tools for image generation
├── Makefile                   # Main build system
└── README.md                  # This file
```

## Build Artifacts

After a successful build, you'll find the following key artifacts in the `output/` directory:

- **`output/fw_payload.bin`** - Complete bootable image: OpenSBI + U-Boot + Linux + initramfs (from `opensbi/build/platform/ikr/firmware/`)
- **`output/fw_payload.elf`** - OpenSBI ELF with payload (from `opensbi/build/platform/ikr/firmware/`)
- **`output/fw_payload.vmf`** - Flash memory image for hardware deployment (generated by `build-board-hex`)
- **`output/cboot_flash.hex`** - Intel HEX format for programming (generated by `build-board-hex`)
- **`output/kernel.mif`** - MIF format (256-bit width) for Quartus FPGA tools (generated by `build-board-mif`)
- **`output/kernel_64b.mif`** - MIF format (64-bit width) for Quartus FPGA tools (generated by `build-board-mif`)
- **`output/Image`** - Linux kernel image (from `linux/arch/riscv/boot/`)
- **`output/u-boot.bin`** - U-Boot bootloader binary (from `u-boot/`)
- **`output/initramfs.cpio.gz`** - Root filesystem image (from `busybox/_install/`)
- **`output/disk.img`** - Virtual disk image containing U-Boot and Linux (generated by `build-disk-image`)

## Configuration

### Customizing the Build

Configuration files for each component are located in the `configs/` directory:

- **OpenSBI**: Platform-specific sources in `opensbi/platform/ikr/`
- **U-Boot**: `configs/uboot/ikr_defconfig`
- **Linux Kernel**: `configs/linux/ikr_defconfig`
- **BusyBox**: `configs/busybox/.config`

To modify configurations:

1. Edit the appropriate config file in `configs/`
2. Rebuild the component using the corresponding `make build-*` target

### Memory Map and Peripheral Addresses

**⚠️ Important:** When changing memory addresses or peripheral configurations (RAM base, UART, PLIC, timer addresses), you must update multiple files to maintain consistency.

See **[docs/MEMORY_MAP.md](docs/MEMORY_MAP.md)** for:
- Current memory layout
- List of all files that need updating for each type of change
- Verification checklist

**Key memory addresses:**
- OpenSBI base: `0x40000000` (`opensbi/platform/ikr/objects.mk`)
- U-Boot base: `0x40200000` (`u-boot/configs/ikr_defconfig`)
- Linux kernel: `0x42000000` (`u-boot/include/configs/ikr.h`)
- UART: `0x00000001` (must match in 5 files - see MEMORY_MAP.md)

### Device Tree

Device tree files in the project:
- `device-tree/ikr.dts` - Primary device tree for Linux boot
- `opensbi/firmware/ikr.dts` - OpenSBI internal device tree

**Important:** Two device trees must stay synchronized. Peripheral addresses (UART, PLIC, timer) must match in both files.

Compiled device trees (`.dtb`) are generated automatically during the build process.

See [docs/device-tree/device-tree.md](docs/device-tree/device-tree.md) for complete documentation and [docs/MEMORY_MAP.md](docs/MEMORY_MAP.md) for synchronization requirements.

## Troubleshooting

### Common Issues

1. **Toolchain build fails**: Ensure all prerequisites are installed (see `docs/PREREQUISITES.md`)
2. **Kernel boot fails at early stage**: Check that rvemu includes MMU fixes (see `docs/rvemu_mmu_issue.md`)
3. **No console output**: Verify console parameter is set to `console=ttyIKR0` or `console=hvc0`
4. **Build artifacts missing**: Run `git submodule update --init --recursive` to initialize submodules
5. **Page faults on device access**: Memory address mismatch - verify all addresses in [docs/MEMORY_MAP.md](docs/MEMORY_MAP.md)
6. **U-Boot doesn't start**: Check `CONFIG_TEXT_BASE` matches `FW_TEXT_START + FW_PAYLOAD_OFFSET`

### Detailed Documentation

For in-depth troubleshooting and technical details, see:
- [docs/MEMORY_MAP.md](docs/MEMORY_MAP.md) - Memory map and file update reference
- [docs/prerequisites-and-issues.md](docs/prerequisites-and-issues.md) - Common build and boot issues
- [docs/rvemu_mmu_issue.md](docs/rvemu_mmu_issue.md) - rvemu MMU implementation details
- [docs/uart_issue_at_kernel.md](docs/uart_issue_at_kernel.md) - UART and console debugging

## Cleaning Up

Remove all build artifacts:

```bash
make clean
```

This cleans the toolchain, OpenSBI, Linux, and U-Boot build directories.

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[docs/PREREQUISITES.md](docs/PREREQUISITES.md)** - Detailed system requirements and dependencies
- **[docs/MEMORY_MAP.md](docs/MEMORY_MAP.md)** - Quick reference for memory addresses and file updates ⭐
- **[docs/device-tree/device-tree.md](docs/device-tree/device-tree.md)** - Device tree guide (DTS/DTB files)
- **[docs/toolchain/toolchain.md](docs/toolchain/toolchain.md)** - RISC-V toolchain build guide (musl vs glibc)
- **[docs/memory-map-and-device-tree.md](docs/memory-map-and-device-tree.md)** - Comprehensive memory layout and device tree guide
- **[docs/prerequisites-and-issues.md](docs/prerequisites-and-issues.md)** - Build troubleshooting guide
- **[docs/linux/](docs/linux/)** - Linux kernel configuration and customization
- **[docs/opensbi/](docs/opensbi/)** - OpenSBI platform development
- **[docs/u-boot/](docs/u-boot/)** - U-Boot integration guide

### Memory Map Changes

When modifying memory addresses or peripheral configurations, consult:
1. **[MEMORY_MAP.md](docs/MEMORY_MAP.md)** for quick reference of what files to update
2. **[memory-map-and-device-tree.md](docs/memory-map-and-device-tree.md)** for detailed procedures

**Critical files that require synchronization:**
- Device trees: `device-tree/ikr.dts`, `opensbi/firmware/ikr.dts`
- OpenSBI: `opensbi/platform/ikr/objects.mk`, `opensbi/platform/ikr/platform.c`
- U-Boot: `u-boot/configs/ikr_defconfig`, `u-boot/include/configs/ikr.h`
- Build scripts: `scripts/build_disk_image.sh`
- Emulator: `rvemu/src/bus.rs`

See [docs/MEMORY_MAP.md](docs/MEMORY_MAP.md) for the complete file update matrix.

## Development Workflow

### Making Changes

1. **Modify source code**: Edit files in the respective component directories (linux/, opensbi/, u-boot/)
2. **Update configurations**: Modify files in `configs/` if needed
3. **Rebuild component**: Run `make build-<component>`
4. **Test**: Run with `make run-rvemu`

### Building for Hardware

To deploy on actual IKR hardware:

1. Build the complete OS: `make build-os`
2. Generate flash images: `make build-board-hex` or `make build-board-mif`
3. Program the board using the generated `.vmf` or `.mif` files in `output/`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Mohamed Elkomy**  
IKR Institute, Stuttgart University

## Acknowledgments

This system integrates the following open-source projects:
- Linux Kernel
- U-Boot Bootloader
- OpenSBI Firmware
- BusyBox
- RISC-V GNU Toolchain
- rvemu RISC-V Emulator

## Contributing

For questions, issues, or contributions, please contact the author or refer to the documentation in the `docs/` directory.

