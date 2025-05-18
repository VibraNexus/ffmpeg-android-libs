# cmake/AndroidFlexPages.cmake
#
# Enable true dual‐page‐size support (4 KB & 16 KB) in NDK r27+

# tell the NDK toolchain to generate flexible page‐size metadata
set(ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES ON CACHE BOOL "" FORCE)

# pass the max‐page‐size flag to the linker
set(CMAKE_SHARED_LINKER_FLAGS
    "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384")
