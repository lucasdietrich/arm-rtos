set(LINKER_SCRIPT "${CMAKE_BINARY_DIR}/MPS2.ld")
set(LINKER_SCRIPT "${LINKER_SCRIPT}" PARENT_SCOPE)
set(CPU "cortex-m3" PARENT_SCOPE)
set(QEMU_MACHINE "mps2-an385" PARENT_SCOPE)
set(ICOUNT_SHIFT 4 PARENT_SCOPE)
set(QEMU_NET_TAP_MODEL_ARG "lan9118" PARENT_SCOPE)

set(BOARD_DEFINES
     # CMSIS
	"-DMPS2_AN385"
	"-DCPU_CFG_NVIC_PRIO_BITS=3"
	"-DARMCM3"
	"-DFCPU=25000000ul"
)
target_compile_definitions(${target} PRIVATE ${BOARD_DEFINES})

message(STATUS "LINKER_SCRIPT: ${LINKER_SCRIPT}")

add_custom_command(
                   OUTPUT ${LINKER_SCRIPT}
                   DEPENDS ${CMAKE_CURRENT_LIST_DIR}/MPS2.ld
                   COMMAND ${CMAKE_C_COMPILER} -P -E -x c -CC 
                        -I${CMAKE_CURRENT_SOURCE_DIR}
                        -o ${LINKER_SCRIPT}
                        MPS2.ld
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                   COMMENT "preprocessing linker script"
                   VERBATIM
                   )
add_custom_target(mps2_linkerscript DEPENDS ${LINKER_SCRIPT})
add_dependencies(${target} mps2_linkerscript)

add_custom_command(
                   OUTPUT pygen.txt
                   COMMAND python ${CMAKE_SOURCE_DIR}/scripts/build/prebuild.py
                   WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                   COMMENT "running python script"
                   VERBATIM
                   )
add_custom_target(pygen DEPENDS "pygen.txt")
add_dependencies(${target} pygen)

target_sources(${target} PRIVATE
     ${CMAKE_CURRENT_LIST_DIR}/startup_MPS2.S
     ${CMAKE_CURRENT_LIST_DIR}/system_CMSDK_CM3.c

     ${DRIVERS}/uart/cmsdk_uart.c
     ${DRIVERS}/device.c
)

target_include_directories(${target} PRIVATE
     ${CMAKE_CURRENT_LIST_DIR}

	${CMSIS}/Device/ARM/ARMCM3/Include
	${CMSIS}/CMSIS/Core/Include

     ${DRIVERS}
)