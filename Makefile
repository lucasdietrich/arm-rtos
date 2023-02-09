## 
## Copyright (c) 2022 Lucas Dietrich <ld.adecy@gmail.com>
## 
## SPDX-License-Identifier: Apache-2.0
## 

# BOARD="mps2_an385"
# BOARD="lm3s6965evb"
BOARD="mps2_an385"

.PHONY: all cmake make qemu run clean

all: cmake make

cmake:
	cmake -DCMAKE_TOOLCHAIN_FILE=./toolchain-arm-none-eabi.cmake \
		-DBOARD=$(BOARD) -S . -B build \
		-DCMAKE_BUILD_TYPE=Debug

make:
	make -C build --no-print-directory

qemu: make
	make -C build qemu --no-print-directory

run: make
	make -C build run --no-print-directory

format:
	find kernel -iname *.h -o -iname *.c -o -iname *.cpp | xargs clang-format -i
	find drivers -iname *.h -o -iname *.c -o -iname *.cpp | xargs clang-format -i
	find samples -iname *.h -o -iname *.c -o -iname *.cpp | xargs clang-format -i

clean:
	rm -rf build