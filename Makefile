SHELL := /bin/bash
export BASH_ENV := $(CURDIR)/scripts/setup-env.sh

.PHONY: all help build-toolchain-musl build-toolchain-glibc build-opensbi build-linux \
        build-rootfs build-linux-embedded-rootfs build-uboot build-disk-image \
        build-opensbi-payload build-os build-board-hex build-board-mif \
        run-qemu run-rvemu clean clean-all

# Default target
all: help

help:
	@echo "IKR RISC-V Embedded Linux Build System"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Main Targets:"
	@echo "  build-os                    - Build complete OS (rootfs + kernel + u-boot + opensbi)"
	@echo "  run-rvemu                   - Run the built system on rvemu emulator"
	@echo "  run-qemu                    - Run the built system on QEMU emulator"
	@echo ""
	@echo "Build Targets:"
	@echo "  build-toolchain-musl        - Build RISC-V toolchain with musl libc"
	@echo "  build-toolchain-glibc       - Build RISC-V toolchain with glibc"
	@echo "  build-rootfs                - Build BusyBox rootfs and pack initramfs.cpio.gz"
	@echo "  build-linux                 - Build Linux kernel"
	@echo "  build-linux-embedded-rootfs - Build Linux kernel with initramfs.cpio.gz embedded"
	@echo "  build-uboot                 - Build U-Boot bootloader"
	@echo "  build-disk-image            - Build virtual disk image with U-Boot and Linux kernel"
	@echo "  build-opensbi               - Build OpenSBI firmware"
	@echo "  build-opensbi-payload       - Build OpenSBI with combined U-Boot and Linux payload"
	@echo ""
	@echo "Hardware Deployment:"
	@echo "  build-board-hex             - Generate Intel HEX and VMF flash images"
	@echo "  build-board-mif             - Generate MIF images for Quartus"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean                       - Clean all build artifacts"
	@echo "  clean-all                   - Clean everything including toolchain"

build-toolchain-musl:
	@echo "Building RISC-V toolchain with musl libc..."
	./scripts/build_toolchain_musl.sh

build-toolchain-glibc: export TOOLCHAIN_LIBC := glibc
build-toolchain-glibc:
	@echo "Building RISC-V toolchain with glibc..."
	./scripts/build_toolchain_glibc.sh

build-opensbi:
	@echo "Building OpenSBI firmware..."
	@make -C opensbi clean 2>/dev/null || true
	./scripts/build_opensbi.sh

build-uboot:
	@echo "Building U-Boot bootloader..."
	@make -C u-boot clean 2>/dev/null || true
	./scripts/build_uboot.sh

build-linux:
	@echo "Building Linux kernel..."
	./scripts/build_linux.sh


build-linux-embedded-rootfs:
	@echo "Building Linux kernel with embedded rootfs..."
	./scripts/build_linux_embedded_rootfs.sh

build-rootfs:
	@echo "Building BusyBox rootfs..."
	./scripts/build_rootfs.sh

build-disk-image:
	@echo "Building disk image..."
	./scripts/build_disk_image.sh

build-opensbi-payload:
	@echo "Building OpenSBI with payload..."
	@make -C opensbi clean 2>/dev/null || true
	./scripts/build_opensbi_payload.sh

build-os: build-rootfs build-linux-embedded-rootfs build-uboot build-disk-image build-opensbi-payload

run-qemu:
	@if [ ! -f opensbi/build/platform/ikr/firmware/fw_payload.bin ]; then \
		echo "Error: fw_payload.bin not found. Run 'make build-os' first."; \
		exit 1; \
	fi
	@if [ ! -f qemu/build/qemu-system-riscv64 ]; then \
		echo "Error: QEMU not found. Build QEMU first."; \
		exit 1; \
	fi
	./qemu/build/qemu-system-riscv64 -M ikr -m 128M -smp 1 -nographic -bios opensbi/build/platform/ikr/firmware/fw_payload.bin

run-rvemu:
	@if [ ! -f output/fw_payload.bin ]; then \
		echo "Error: output/fw_payload.bin not found. Run 'make build-os' first."; \
		exit 1; \
	fi
	@if [ ! -f rvemu/target/release/rvemu-cli ]; then \
		echo "Error: rvemu not found at rvemu/target/release/rvemu-cli"; \
		exit 1; \
	fi
	rvemu/target/release/rvemu-cli -k output/fw_payload.bin

clean:
	@echo "Cleaning build artifacts..."
	@make -C opensbi clean 2>/dev/null || true
	@make -C linux clean 2>/dev/null || true
	@make -C u-boot clean 2>/dev/null || true
	@make -C busybox clean 2>/dev/null || true
	@rm -rf output/*
	@echo "Clean complete."

clean-all: clean
	@echo "Cleaning everything including toolchain..."
	@make -C riscv-gnu-toolchain clean 2>/dev/null || true
	@rm -rf riscv64-unknown-linux-musl riscv64-unknown-linux-gnu
	@echo "Clean all complete."

# Board flash hex generation
# Produces output/fw_payload.vmf (VMF format) and output/cboot_flash.hex (Intel HEX)
# for programming the IKR board via flash memory.
build-board-hex:
	@if [ ! -f output/fw_payload.bin ]; then \
		echo "ERROR: output/fw_payload.bin not found. Run 'make build-os' first."; \
		exit 1; \
	fi
	@echo "Generating board flash images from output/fw_payload.bin..."
	@mkdir -p output
	python3 tools/create_flash_img.py \
		output/fw_payload.bin \
		output/fw_payload.vmf \
		2000000 \
		40000000 \
		40000000
	@echo "Done."
	@echo "  Flash VMF  : output/fw_payload.vmf"
	@echo "  Intel HEX  : output/cboot_flash.hex"

# MIF generation for Quartus SOF update
# Produces output/kernel.mif and output/kernel_64b.mif from output/fw_payload.bin
build-board-mif:
	@if [ ! -f output/fw_payload.bin ]; then \
		echo "ERROR: output/fw_payload.bin not found. Run 'make build-os' first."; \
		exit 1; \
	fi
	@echo "Generating MIF files for Quartus..."
	@mkdir -p output
	$(eval FW_SIZE_256 := $(shell python3 -c "import os,math; fw=os.path.getsize('output/fw_payload.bin'); w=256; print(math.ceil(fw*8/w)+1)"))
	$(eval FW_SIZE_64  := $(shell python3 -c "import os,math; fw=os.path.getsize('output/fw_payload.bin'); w=64;  print(math.ceil(fw*8/w)+1)"))
	python3 tools/dat2mif.py \
		-d $(FW_SIZE_256) \
		-w 256 \
		-p 0 \
		-ar DEC \
		output/fw_payload.bin \
		output/kernel.mif
	python3 tools/dat2mif.py \
		-d $(FW_SIZE_64) \
		-w 64 \
		-p 0 \
		-ar DEC \
		output/fw_payload.bin \
		output/kernel_64b.mif
	@echo "Done."
	@echo "  kernel.mif (256-bit): output/kernel.mif (DEPTH=$(FW_SIZE_256))"
	@echo "  kernel_64b.mif (64-bit): output/kernel_64b.mif (DEPTH=$(FW_SIZE_64))"