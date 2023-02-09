target_include_directories(${target} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_sources(${target} PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/kernel.c
    ${CMAKE_CURRENT_SOURCE_DIR}/logging.c
)