project(ponyc VERSION ${PONYC_VERSION} LANGUAGES C CXX)

add_executable(ponyc main.c)

target_include_directories(ponyc
    PRIVATE ../../src/common
    PRIVATE ../../src/libponyc
    PRIVATE ../../build/libs/include
)

target_link_directories(ponyc
    PRIVATE ../../build/libs/lib
)

if (MSVC)
    target_link_libraries(ponyc
        PRIVATE libponyc
        PRIVATE libponyrt
        PRIVATE blake2
        PRIVATE dbghelp
        PRIVATE ucrt
        PRIVATE Ws2_32
        PRIVATE Shlwapi
    )

    set_source_files_properties(main.c PROPERTIES LANGUAGE CXX)

    llvm_config(ponyc all)

    get_target_property(TARGET_LIBRARIES ponyc LINK_LIBRARIES)
    LIST(REMOVE_ITEM TARGET_LIBRARIES LTO)
    set_property(TARGET ponyc PROPERTY LINK_LIBRARIES ${TARGET_LIBRARIES})

    # copy libponyrt to the ponyc directory for use when linking pony programs
    add_custom_command(TARGET ponyc POST_BUILD
        COMMAND $<$<CONFIG:Debug>:${CMAKE_COMMAND}> ARGS -E copy ${libponyrt_BINARY_DIR}/debug/libponyrt.lib ${CMAKE_BINARY_DIR}/../debug/libponyrt.lib
        COMMAND $<$<CONFIG:Release>:${CMAKE_COMMAND}> ARGS -E copy ${libponyrt_BINARY_DIR}/release/libponyrt.lib ${CMAKE_BINARY_DIR}/../release/libponyrt.lib
        COMMAND $<$<CONFIG:RelWithDebInfo>:${CMAKE_COMMAND}> ARGS -E copy ${libponyrt_BINARY_DIR}/relwithdebinfo/libponyrt.lib ${CMAKE_BINARY_DIR}/../relwithdebinfo/libponyrt.lib
        COMMAND $<$<CONFIG:MinSizeRel>:${CMAKE_COMMAND}> ARGS -E copy ${libponyrt_BINARY_DIR}/minsizerel/libponyrt.lib ${CMAKE_BINARY_DIR}/../minsizerel/libponyrt.lib
    )
else()
    target_link_libraries(ponyc PRIVATE
        libponyc
        libponyrt
        blake2
    )

    llvm_config(ponyc all)

    if(${CMAKE_HOST_SYSTEM_NAME} MATCHES "Darwin")
        target_link_libraries(ponyc PRIVATE dl)
    elseif(${CMAKE_HOST_SYSTEM_NAME} MATCHES "BSD")
        target_link_libraries(ponyc PRIVATE execinfo)
    else()
        target_link_libraries(ponyc PRIVATE atomic dl)
        target_link_options(ponyc PRIVATE "-static-libstdc++")
    endif()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_link_options(ponyc PRIVATE "-static-libgcc")
    endif()

    # copy libponyrt to the ponyc directory for use when linking pony programs
    add_custom_command(TARGET ponyc POST_BUILD
        COMMAND $<$<CONFIG:Debug>:${CMAKE_COMMAND}> ARGS -E copy ${libponyrt_BINARY_DIR}/libponyrt.a ${CMAKE_BINARY_DIR}/../debug/libponyrt-pic.a
        COMMAND $<$<CONFIG:Release>:${CMAKE_COMMAND}> ARGS -E copy ${libponyrt_BINARY_DIR}/libponyrt.a ${CMAKE_BINARY_DIR}/../release/libponyrt-pic.a
        COMMAND $<$<CONFIG:RelWithDebInfo>:${CMAKE_COMMAND}> ARGS -E copy ${libponyrt_BINARY_DIR}/libponyrt.a ${CMAKE_BINARY_DIR}/../relwithdebinfo/libponyrt-pic.a
        COMMAND $<$<CONFIG:MinSizeRel>:${CMAKE_COMMAND}> ARGS -E copy ${libponyrt_BINARY_DIR}/minsizerel/libponyrt.a ${CMAKE_BINARY_DIR}/../minsizerel/libponyrt-pic.a
    )
endif (MSVC)
