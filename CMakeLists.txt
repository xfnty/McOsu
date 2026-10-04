cmake_minimum_required(VERSION 3.12.0)

set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_STANDARD 20)

project("McOsu" LANGUAGES C CXX)

file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS "src/*.c" "src/*.cpp" "src/*.h" "src/*.hpp")
file(GLOB_RECURSE INCLUDES CONFIGURE_DEPENDS LIST_DIRECTORIES true "src/*/")
file(GLOB_RECURSE LIBS "libraries/*.lib")

add_executable(McOsu WIN32 ${SOURCES} "src/info.rc")
target_link_libraries(
    McOsu PRIVATE
    ${LIBS}
    Dbghelp.lib
    d3d11.lib
    d3dcompiler.lib
    dxgi.lib
    user32.lib
    kernel32.lib
    comdlg32.lib
    Advapi32.lib
    ucrt.lib
    vcruntime.lib
    msvcrt.lib
    Comctl32.lib
    gdi32.lib
    Shell32.lib
)
target_include_directories(
    McOsu PRIVATE
    "libraries/bass/include"
    "libraries/bassfx/include"
    "libraries/directx/include"
    "libraries/freetype/include"
    "libraries/libjpeg/include"
    ${INCLUDES}
)
target_compile_definitions(
    McOsu PRIVATE
    NOMINMAX
    WIN32
    FT_CONFIG_OPTION_NO_ASSEMBLER
)
target_compile_options(
    McOsu PRIVATE
    -fmessage-length=0
    -Wno-comment
    -Wno-macro-redefined
    -Wno-class-conversion
    -Wno-sign-compare
    -Wno-unused-local-typedefs
    -Wno-reorder
    -Wno-switch
    -Wno-deprecated-declarations
    -Wno-vla-cxx-extension
    -Wno-unused-but-set-variable
    -fno-stack-check
    -fno-stack-protector
    -mno-stack-arg-probe
    -Wno-new-returns-null
    -Wno-tautological-constant-out-of-range-compare
    -Wno-builtin-requires-header
)
target_link_options(
    McOsu PRIVATE
    -Wl,/SAFESEH:no
    -Wl,/MACHINE:x86
    -Wl,/NOIMPLIB
    -Wl,/NOEXP
    -Wl,/INCREMENTAL:NO
)
set_target_properties(
    McOsu PROPERTIES
    OUTPUT_NAME "McEngine"
)

add_custom_command(
    TARGET McOsu
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_CURRENT_SOURCE_DIR}/build"
            "$<TARGET_FILE_DIR:McOsu>"
    COMMENT "Copying assets ..."
)
