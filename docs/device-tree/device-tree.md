# Device Tree

## Files used

Two device tree source files describe the IKR RISC-V platform:

- **Primary:** `device-tree/ikr.dts` — Linux boot device tree
- **OpenSBI:** `opensbi/firmware/ikr.dts` — OpenSBI internal device tree

Both must stay synchronized for peripheral addresses (UART, PLIC, timer).

## What it does

- Describes hardware layout to OpenSBI and Linux kernel
- Defines memory regions, CPU, peripherals, interrupt routing
- Compiled from `.dts` (source) to `.dtb` (binary) format
- Used by OpenSBI at runtime and passed to Linux

## Key components defined

### CPU
- **Model:** Single RISC-V 64-bit core (rv64imafdc)
- **MMU:** Sv39 virtual memory
- **Timebase:** 10 MHz
- **Interrupt controller:** RISC-V CPU INTC

### Memory layout
- **Boot ROM:** `0x3ffff000` (4 KiB) — reset vector
- **Internal RAM:** `0x40000000` (32 MiB) — OpenSBI + U-Boot
- **External RAM:** `0x44000000` (1 GiB) — Linux + userspace
- **Total window:** `0x40000000` (128 MiB for Linux)

### Peripherals
- **UART:** `0x00000001` (16 B) — IKR custom UART, PLIC IRQ 10
- **PLIC:** `0x00200100` (~2 MiB) — 128 interrupt sources
- **Timer:** `0x00000080` (mtime), `0x00000088` (mtimecmp)

## File differences

### `ikr.dts` (Primary Linux DTS)

Located in `device-tree/` directory. Features:
- Single memory node: `memory@40000000` (128 MiB window)
- Used for Linux boot
- Compiled to `ikr.dtb` and passed to OpenSBI via `FW_FDT_PATH`
- Console config: `bootargs = "earlycon=sbi console=hvcttyIKR0 ..."`

### `opensbi/firmware/ikr.dts` (OpenSBI Internal)

Located in OpenSBI firmware directory. Features:
- Split memory: `int_ram@40000000` (32 MiB), `ext_ram@44000000` (1 GiB)
- Includes `bootrom@3ffff000` node
- Used by OpenSBI for platform initialization and domain protection
- Must match peripheral addresses from main `device-tree/ikr.dts`

**Critical:** UART, PLIC, and timer addresses must be identical in both files.

## How device trees are compiled

Device trees are compiled during component builds:

**OpenSBI build:**
```bash
dtc -I dts -O dtb -o ikr.dtb device-tree/ikr.dts
```

Compiled by:
- `scripts/build_opensbi.sh` → outputs to `output/ikr.dtb`
- `scripts/build_opensbi_payload.sh` → outputs to `output/ikr.dtb`

**Command:**
- `dtc` — Device Tree Compiler (from `device-tree-compiler` package)
- `-I dts` — input format (device tree source)
- `-O dtb` — output format (device tree blob)

## Prerequisites

Device tree compiler must be installed:

```bash
sudo apt install -y device-tree-compiler
```

Check version:
```bash
dtc --version
```

## How to modify

### 1. Edit device tree source

Edit `device-tree/ikr.dts` for changes that affect Linux:

```bash
vim device-tree/ikr.dts
```

If changing peripheral addresses, also edit `opensbi/firmware/ikr.dts`.

### 2. Rebuild components

After editing device trees, rebuild affected components:

```bash
# Rebuild OpenSBI (compiles DTS and uses it)
make build-opensbi-payload

# Or full rebuild
make build-os
```

The build scripts automatically recompile `.dts` to `.dtb`.

## Common modifications

### Changing memory size

**File:** `device-tree/ikr.dts`
```dts
memory@40000000 {
    device_type = "memory";
    reg = <0x0 0x40000000 0x0 0x08000000>;  /* 128 MiB */
};
```

Change the last value (size): `0x08000000` = 128 MiB, `0x10000000` = 256 MiB

Also update `opensbi/firmware/ikr.dts` memory nodes.

See [../MEMORY_MAP.md](../MEMORY_MAP.md) for complete procedure.

### Changing UART address

**⚠️ Critical:** Must update 5 files (see [../MEMORY_MAP.md](../MEMORY_MAP.md)):
1. `device-tree/ikr.dts` — `uart@1` node
2. `opensbi/firmware/ikr.dts` — `uart@1` node
3. `opensbi/platform/ikr/platform.c` — `PLATFORM_UART_ADDR`
4. `linux/drivers/tty/serial/ikr_uart.c` — driver code
5. `rvemu/src/bus.rs` — emulator bus mapping

### Changing console kernel parameters

**File:** `device-tree/ikr.dts`
```dts
chosen {
    bootargs = "earlycon=sbi console=ttyIKR0 loglevel=8";
    stdout-path = "serial0";
};
```

- `earlycon=sbi` — early console via SBI
- `console=ttyIKR0` — main console via IKR UART driver
- `console=hvc0` — alternative: use SBI console
- `loglevel=8` — kernel log level (0-8, higher = more verbose)

### Adding a new peripheral

1. Add device node in `device-tree/ikr.dts`:
```dts
newdevice@address {
    compatible = "vendor,device";
    reg = <0x0 0xADDRESS 0x0 0xSIZE>;
    interrupt-parent = <&plic>;
    interrupts = <IRQ_NUM>;
};
```

2. Mirror in `opensbi/firmware/ikr.dts`
3. Update platform code in `opensbi/platform/ikr/platform.c`
4. Add driver support in Linux kernel
5. Update emulator (`rvemu/src/bus.rs`)

## Device tree structure explained

### Standard properties

- `compatible` — identifies device type/driver binding
- `reg` — address and size: `<addr_hi addr_lo size_hi size_lo>`
- `#address-cells` — number of cells for child addresses
- `#size-cells` — number of cells for sizes
- `interrupts` — interrupt numbers
- `interrupt-parent` — pointer to interrupt controller

### RISC-V specific

- `riscv,isa` — ISA string (e.g., `rv64imafdc`)
- `mmu-type` — MMU type (`riscv,sv39` for Sv39 paging)
- `timebase-frequency` — timer frequency in Hz
- `riscv,ndev` — number of PLIC interrupt sources

### IKR platform specific

- `compatible = "ikr,rvemu"` — identifies IKR platform
- `model = "ikr-riscv64"` — platform model name
- `compatible = "ikr,uart"` — IKR UART driver binding

## Compiled output

After build:
- **Source:** `device-tree/ikr.dts` (human-readable)
- **Binary:** `ikr.dtb` (compiled, used at runtime)
- **Location:** `output/ikr.dtb`

OpenSBI uses the compiled DTB at runtime:
```bash
# Build flag in OpenSBI
FW_FDT_PATH=output/ikr.dtb
```

## Verification

### Check compiled device tree

Decompile `.dtb` back to readable format:

```bash
dtc -I dtb -O dts -o ikr-check.dts ikr.dtb
```

View specific nodes:

```bash
dtc -I dtb -O dts ikr.dtb | grep -A 10 "uart@"
```

### Validate syntax

```bash
dtc -I dts -O dtb device-tree/ikr.dts -o /dev/null
# If no errors, syntax is valid
```

## Troubleshooting

### "dtc: command not found"

**Solution:** Install device tree compiler:
```bash
sudo apt install -y device-tree-compiler
```

### "Error: ikr.dtb not found"

**Solution:** Rebuild OpenSBI to compile device tree:
```bash
make build-opensbi-payload
```

### System boots but UART not working

**Cause:** Address mismatch between device trees and driver/platform code  
**Solution:** Verify all UART addresses match (see [../MEMORY_MAP.md](../MEMORY_MAP.md))

### Page faults when accessing devices

**Cause:** Device address in DTS doesn't match actual hardware/emulator  
**Solution:** Check both `device-tree/ikr.dts` and `opensbi/firmware/ikr.dts` match `rvemu/src/bus.rs`

### Kernel panic: "No init found"

**Cause:** May be memory size mismatch or wrong bootargs  
**Solution:** Verify memory node size matches actual RAM, check `chosen/bootargs`

## Related documentation

- **Memory Map:** [../MEMORY_MAP.md](../MEMORY_MAP.md) — address layout and update procedures
- **Comprehensive Guide:** [../memory-map-and-device-tree.md](../memory-map-and-device-tree.md) — detailed DTS reference
- **OpenSBI:** [../opensbi/opensbi.md](../opensbi/opensbi.md) — how OpenSBI uses device tree
- **Prerequisites:** [../PREREQUISITES.md](../PREREQUISITES.md) — device-tree-compiler installation

## External resources

- [Device Tree Specification](https://www.devicetree.org/specifications/)
- [Linux Kernel Device Tree Documentation](https://www.kernel.org/doc/html/latest/devicetree/)
- [RISC-V Device Tree Bindings](https://github.com/torvalds/linux/tree/master/Documentation/devicetree/bindings/riscv)
