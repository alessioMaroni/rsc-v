ALR ?= .bin/alr-fhs
OVMF_PATH ?= /usr/share/edk2/ovmf/OVMF_CODE.fd
USER ?= $(shell whoami)

.PHONY: setup build-ada build debug test run run-debug run-test clean flash_firmware forced_opencode gdb serial

# WORKFLOW:
# Terminal 1: make build flash_firmware
# Terminal 2: make forced_opencode
# Terminal 3: make gdb
# Terminal 4: make serial

setup:
	echo "Running system setup...."
	# TODO: finisc the setup method

build-ada:
	chmod +x $(ALR)
	mkdir -p ada/rts/adalib
	mkdir -p ada/time/obj
	$(ALR) -C ada/time exec -- riscv64-elf-gcc -c src/time.adb \
		--RTS=$(PWD)/ada/rts \
		-gnatg \
		-gnatyN \
		-O2 \
		-g0 \
		-gnatp \
		-fno-PIC \
		-march=rv32imac \
		-mabi=ilp32 \
		-o obj/time.o

build: build-ada
	cargo build --target riscv32imac-unknown-none-elf --release
	python3 scripts/uf2conv.py .build/kernel.bin -f 0xe48bff56 -o .build/kernel.uf2

flash_firmware:
	sudo picotool reboot -u
	sleep 5
	cp RPI_PICO2-RISCV-20260824-v1.29.0.uf2 /run/media/$(USER)/RP2350/

opencode:
	sleep 3
	sudo openocd -f interface/cmsis-dap.cfg -c "adapter speed 500" -f target/rp2350-riscv.cfg

# NOTE: Run `make gdb` on another terminal
#
# Command to run on gdb:
# 1. set mem inaccessible-by-default
# 2. target extended-remote :3333
# 3. monitor reset halt
# 4. load
# 5. break _main
# 6. continue
gdb:
	riscv64-elf-gdb target/riscv32imac-unknown-none-elf/release/RSC-V-kernel

# NOTE:
# Run `make serial` on another terminal
# To exit from picocom: press Ctrl+A followed by Ctrl+X
serial:
	sudo picocom -b 115200 /dev/ttyACM0 --nolock
