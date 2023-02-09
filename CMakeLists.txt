## 
## Copyright (c) 2022 Lucas Dietrich <ld.adecy@gmail.com>
## 
## SPDX-License-Identifier: Apache-2.0
## 

cmake_minimum_required(VERSION 3.2)

project(arm-rtos)

# https://github.com/zephyrproject-rtos/zephyr/blob/main/cmake/modules/extensions.cmake#L1487-L1497
function(add_subdirectory_ifdef feature_toggle source_dir)
  if(${${feature_toggle}})
    add_subdirectory(${source_dir} ${ARGN})
  endif()
endfunction()

function(target_sources_ifdef feature_toggle target scope item)
  if(${${feature_toggle}})
    target_sources(${target} ${scope} ${item} ${ARGN})
  endif()
endfunction()

set(CC ${CMAKE_SIZE_UTIL})
set(SZ ${CMAKE_SIZE_UTIL})
set(OBJCOPY ${CMAKE_OBJCOPY_UTIL})
set(OBJDUMP ${CMAKE_OBJDUMP_UTIL})
set(NM ${CMAKE_NM_UTIL})
set(READELF ${CMAKE_READELF_UTIL})

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CONFIG_NETWORKING OFF)

enable_language(C ASM)

# Check that the target is statically linked (i.e. "-rdynamic" not set)
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")

set(CMAKE_C_FLAGS_DEBUG "-gdwarf-4 -g3 -Og")
message(STATUS CMAKE_C_FLAGS_DEBUG: ${CMAKE_C_FLAGS_DEBUG})

set(ELF_PATH "${CMAKE_BINARY_DIR}/${target}")
set(target "${PROJECT_NAME}.elf")

set(ICOUNT_SHIFT 0)
set(QEMU_NET_TAP_MODEL_ARG "")

set(DEFAULT_BOARD "mps2_an385")

set(MODULES ${CMAKE_SOURCE_DIR}/modules)
set(CMSIS ${MODULES}/CMSIS_5)
set(MBEDOS ${MODULES}/mbed-os)

set(DRIVERS ${CMAKE_SOURCE_DIR}/drivers)

################################################################################
# Create EXE
add_executable(${target})

if (NOT DEFINED BOARD)
	message(STATUS "Board not defined, selecting default board ${DEFAULT_BOARD}")
	set(BOARD ${DEFAULT_BOARD})
else()
	message(STATUS "Board: ${BOARD}")
endif()

################################################################################

# Sources

add_subdirectory(samples/first)
add_subdirectory(boards/${BOARD})
add_subdirectory(kernel)

################################################################################

set_target_properties(${target} PROPERTIES LINK_DEPENDS "${LINKER_SCRIPT}")

target_compile_options(${target} PRIVATE
	-mcpu=${CPU}
	-mthumb

	-fdata-sections
	-ffunction-sections

	-Wall

	# Complaints too much without this
	-Wno-maybe-uninitialized
)

target_compile_definitions(${target} PRIVATE ${ARCH_DEFINES})

target_link_options(${target} PRIVATE
	-mcpu=${CPU}
	-mthumb

	-T${LINKER_SCRIPT}

	-lc
	-lm
	# -nostdlib
	# -lnosys
	# -specs=nano.specs
	
	# already defined in the toolchain
	# -specs=nano.specs
	-Wl,-Map=${PROJECT_NAME}.map,--cref
	-Wl,--gc-sections
	-Wl,--print-memory-usage
)

# Print size of executable
add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${SZ} -G -d ${target} > ${PROJECT_NAME}.size.txt
)

# Convert to hex & bin
add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${OBJCOPY} -O ihex ${target} ${PROJECT_NAME}.hex
        COMMAND ${OBJCOPY} -O binary -S ${target} ${PROJECT_NAME}.bin)

if(DEFINED DO_DISASSEMBLY AND DO_DISASSEMBLY STREQUAL 1) 
	# disassembly
	add_custom_command(TARGET ${target} POST_BUILD
		COMMAND ${OBJDUMP} -S ${target} > objdump_src.s VERBATIM
		COMMAND ${OBJDUMP} -d ${target} > objdump.s VERBATIM
		COMMAND ${OBJDUMP} -D ${target} > objdump_all.s VERBATIM
		COMMAND ${OBJDUMP} -h ${target} > objdump_sections.s VERBATIM
		COMMAND ${READELF} -a ${target} > readelf.txt VERBATIM
		COMMAND ${NM} --print-size --size-sort --radix=x ${target} > nm.txt VERBATIM
		DEPENDS ${target}
	)
endif()

# If CONFIG_NETWORKING is set, define QEMU_NET_ARGS
if(DEFINED CONFIG_NETWORKING AND CONFIG_NETWORKING STREQUAL 1)
	if (QEMU_NET_TAP_MODEL_ARG STREQUAL "")
		message(FATAL_ERROR "QEMU_NET_TAP_MODEL_ARG is not set")
	endif()
	set(QEMU_NET_ARGS "-nic tap,model=${QEMU_NET_TAP_MODEL_ARG},script=no,downscript=no,ifname=meth")
else()
	set(QEMU_NET_ARGS "")
endif()

# Tips
separate_arguments(QEMU_NET_ARGS)

# generate custom target to debug in qemu
add_custom_target(qemu
	COMMAND qemu-system-arm -cpu ${CPU} -machine ${QEMU_MACHINE} -nodefaults -nographic -semihosting -icount shift=${ICOUNT_SHIFT},align=off,sleep=on -rtc clock=vm -vga none -nographic -device loader,file=${target} -pidfile qemu.pid -chardev stdio,id=myCon -serial chardev:myCon -chardev file,id=myFile,mux=on,path=io.txt -serial chardev:myFile -serial chardev:myFile -serial chardev:myFile -serial chardev:myFile ${QEMU_NET_ARGS} -s -S
)

# generate custom command to run only in qemu
add_custom_target(run
	COMMAND qemu-system-arm -cpu ${CPU} -machine ${QEMU_MACHINE} -nodefaults -nographic -semihosting -icount shift=${ICOUNT_SHIFT},align=off,sleep=on -rtc clock=vm -vga none -nographic -device loader,file=${target} -pidfile qemu.pid -chardev stdio,id=myCon -serial chardev:myCon -chardev file,id=myFile,mux=on,path=io.txt -serial chardev:myFile -serial chardev:myFile -serial chardev:myFile -serial chardev:myFile ${QEMU_NET_ARGS}
)