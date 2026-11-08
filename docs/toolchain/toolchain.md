# RISC-V GNU Toolchain

## Current version used

- Toolchain: `2026.04.05`
- GCC: `14.x`
- Binutils: `2.42+`

## What it does

- Builds RISC-V cross-compiler toolchain from `riscv-gnu-toolchain/`
- Supports two C library variants: **musl** (default) or **glibc**
- Produces complete toolchain for cross-compiling all system components
- Installs to separate directories to avoid conflicts

## Toolchain variants

### musl libc (default, recommended)

**Triple:** `riscv64-unknown-linux-musl`  
**Install path:** `riscv64-unknown-linux-musl/`  
**Use for:** Embedded systems, lightweight binaries, static linking

### glibc (GNU C Library)

**Triple:** `riscv64-unknown-linux-gnu`  
**Install path:** `riscv64-unknown-linux-gnu/`  
**Use for:** Full POSIX compliance, mainstream Linux compatibility

Both toolchains can coexist. Select one with the `TOOLCHAIN_LIBC` variable
(`musl` by default); `scripts/setup-env.sh` derives `TARGET`, `TOOLCHAIN_DIR`
and `CROSS_COMPILE` from it:

```bash
make build-toolchain-glibc
make clean
make build-os TOOLCHAIN_LIBC=glibc
```

Run `make clean` when switching libc so no objects built with the other
toolchain are reused.

## Architecture and ABI

- **Arch:** `rv64ima_zicsr_zifencei`
  - rv64i: 64-bit base integer ISA
  - m: Integer multiplication/division
  - a: Atomic instructions
  - Zicsr: CSR instructions
  - Zifencei: Instruction-fetch fence
- **ABI:** `lp64` (LP64 calling convention)
- **Languages:** C, C++

## Prerequisites

System packages (on Debian/Ubuntu):

```bash
sudo apt install -y \
    autoconf automake autotools-dev \
    curl python3 python3-pip python3-toml \
    libmpc-dev libmpfr-dev libgmp-dev \
    gawk build-essential bison flex texinfo \
    gperf libtool patchutils bc zlib1g-dev \
    libexpat-dev libslirp-dev libncurses-dev \
    ninja-build git cmake libglib2.0-dev
```

**Build requirements:**
- Disk space: ~10-15 GB
- RAM: 4 GB minimum, 8 GB recommended
- Time: 30-90 minutes (depends on CPU cores)

See [../PREREQUISITES.md](../PREREQUISITES.md) for complete details.

## How to build

### Via Makefile (recommended)

**musl variant:**
```bash
make build-toolchain-musl
```

**glibc variant:**
```bash
make build-toolchain-glibc
```

### Manual build

**1. Initialize submodules:**
```bash
git submodule update --init --recursive
```

**2. Configure and build (musl):**
```bash
cd riscv-gnu-toolchain
./configure \
    --prefix="${PWD}/../riscv64-unknown-linux-musl" \
    --with-arch=rv64ima_zicsr_zifencei \
    --with-abi=lp64 \
    --with-languages=c,c++ \
    --disable-multilib
make musl -j$(nproc)
```

**3. Configure and build (glibc):**
```bash
cd riscv-gnu-toolchain
./configure \
    --prefix="${PWD}/../riscv64-unknown-linux-gnu" \
    --with-arch=rv64ima_zicsr_zifencei \
    --with-abi=lp64 \
    --with-languages=c,c++ \
    --disable-multilib
make linux -j$(nproc)
```

## Build scripts

- `scripts/build_toolchain_musl.sh` — build musl variant
- `scripts/build_toolchain_glibc.sh` — build glibc variant
- `scripts/setup-env.sh` — environment setup (sets `TARGET`, `CROSS_COMPILE`, `PATH`)

## Environment variables

Set by `scripts/setup-env.sh`:

```bash
TARGET=riscv64-unknown-linux-musl       # or riscv64-unknown-linux-gnu
TOOLCHAIN_DIR="${ROOT_DIR}/${TARGET}"
PATH="${TOOLCHAIN_DIR}/bin:${PATH}"
CROSS_COMPILE="riscv64-unknown-linux-musl-"  # or -gnu-
ARCH="riscv"
ARCH_FLAGS="-march=rv64ima_zicsr_zifencei -mabi=lp64"
```

## Compiler binaries provided

After build, the toolchain provides:

```
riscv64-unknown-linux-musl-gcc        # C compiler
riscv64-unknown-linux-musl-g++        # C++ compiler
riscv64-unknown-linux-musl-as         # Assembler
riscv64-unknown-linux-musl-ld         # Linker
riscv64-unknown-linux-musl-ar         # Archiver
riscv64-unknown-linux-musl-objcopy    # Object copy
riscv64-unknown-linux-musl-objdump    # Object dump
riscv64-unknown-linux-musl-gdb        # Debugger
```

(Replace `musl` with `gnu` for glibc variant)

## Components that use this toolchain

All system components depend on the toolchain:

- OpenSBI M-mode firmware
- U-Boot bootloader
- Linux kernel
- BusyBox rootfs

**Important:** All must be built with the same toolchain variant (musl or glibc).

## Switching between musl and glibc

1. Edit `scripts/setup-env.sh`:
   ```bash
   # For musl:
   export TARGET=riscv64-unknown-linux-musl
   export CROSS_COMPILE="riscv64-unknown-linux-musl-"
   
   # For glibc:
   # export TARGET=riscv64-unknown-linux-gnu
   # export CROSS_COMPILE="riscv64-unknown-linux-gnu-"
   ```

2. Rebuild all components:
   ```bash
   make clean
   make build-os
   ```

Toolchains install to separate directories, so both can be built without conflict.

## Output

- **musl toolchain:** `riscv64-unknown-linux-musl/bin/` (compilers, tools)
- **glibc toolchain:** `riscv64-unknown-linux-gnu/bin/` (compilers, tools)

## Cleaning

**Clean build artifacts:**
```bash
make -C riscv-gnu-toolchain clean
```

**Remove installed toolchain:**
```bash
rm -rf riscv64-unknown-linux-musl/   # musl
rm -rf riscv64-unknown-linux-gnu/    # glibc
```

**Complete clean (all components):**
```bash
make clean-all
```
