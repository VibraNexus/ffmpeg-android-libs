cmake_minimum_required(VERSION 3.21)
project(ffmpeg_android_minimal NONE)
message(STATUS "CMake version: ${CMAKE_VERSION}")
message(STATUS "Android NDK: ${CMAKE_ANDROID_NDK}")
message(STATUS "CMAKE_ANDROID_API = ${CMAKE_ANDROID_API}")
message(STATUS "CMAKE_SYSTEM_NAME = ${CMAKE_SYSTEM_NAME}")
message(STATUS "CMAKE_SYSTEM_VERSION = ${CMAKE_SYSTEM_VERSION}")
message(STATUS "CMAKE_HOST_SYSTEM_VERSION = ${CMAKE_HOST_SYSTEM_VERSION}")
message(STATUS "ANDROID_PLATFORM = ${ANDROID_PLATFORM}")


# Ensure Android cross-compile
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Android")
  message(FATAL_ERROR "Build requires Android NDK (use -DCMAKE_TOOLCHAIN_FILE).")
endif()

# Load flexible page-size support
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(AndroidFlexPages)
message(STATUS "Flexible page sizes: ${ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES}, max-page-size=${MAX_PAGE_SIZE}")

include(ExternalProject)

# FFmpeg source comes from pre-clone in repo root
set(FFMPEG_SOURCE_DIR  "${CMAKE_SOURCE_DIR}/ffmpeg")
set(FFMPEG_INSTALL_DIR "${CMAKE_BINARY_DIR}/${CMAKE_ANDROID_ARCH_ABI}/ffmpeg-install")
set(FFMPEG_BUILD_DIR   "${CMAKE_BINARY_DIR}/${CMAKE_ANDROID_ARCH_ABI}/ffmpeg-build")

message(STATUS "Building for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
if(CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
  set(FFMPEG_TARGET_HOST aarch64-linux-android)
  set(FFMPEG_ARCH aarch64)
  set(FFMPEG_CPU armv8-a)
elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a")
  set(FFMPEG_TARGET_HOST armv7a-linux-androideabi)
  set(FFMPEG_ARCH arm)
  set(FFMPEG_CPU armv7-a)
else()
  message(FATAL_ERROR "Unsupported ANDROID_ABI: ${CMAKE_ANDROID_ARCH_ABI}")
endif()

# NDK toolchain paths
# Prefer the tag exported by the Android toolchain file:
if (DEFINED ANDROID_HOST_TAG)
  set(NDK_TOOLCHAIN "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/${ANDROID_HOST_TAG}")
else()
  # Fallback: lowercase “Linux-x86_64” → “linux-x86_64”
  string(TOLOWER "${CMAKE_HOST_SYSTEM_NAME}-${CMAKE_HOST_SYSTEM_PROCESSOR}" NDK_HOST_TAG)
  set(NDK_TOOLCHAIN "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/${NDK_HOST_TAG}")
endif()
message(STATUS "NDK_TOOLCHAIN = ${NDK_TOOLCHAIN}")

message(STATUS "Cross prefix base = ${NDK_TOOLCHAIN}/bin/${FFMPEG_TARGET_HOST}-")
set(FFMPEG_CROSS_PREFIX "${NDK_TOOLCHAIN}/bin/${FFMPEG_TARGET_HOST}-")
message(STATUS "FFMPEG_CROSS_PREFIX = ${FFMPEG_CROSS_PREFIX}")


set(FFMPEG_CC "${NDK_TOOLCHAIN}/bin/${FFMPEG_TARGET_HOST}${ANDROID_PLATFORM}-clang")
message(STATUS "FFMPEG_CC = ${FFMPEG_CC}")

message(STATUS "Configuring ExternalProject ffmpeg...")
ExternalProject_Add(ffmpeg
  PREFIX            ${CMAKE_BINARY_DIR}/ffmpeg
  SOURCE_DIR        ${FFMPEG_SOURCE_DIR}
  BINARY_DIR        ${FFMPEG_BUILD_DIR}
  INSTALL_DIR       ${FFMPEG_INSTALL_DIR}
  DOWNLOAD_COMMAND  ""
  UPDATE_COMMAND    ""
  CONFIGURE_COMMAND ${FFMPEG_SOURCE_DIR}/configure
    --prefix=${FFMPEG_INSTALL_DIR}
    --target-os=android
    --arch=${FFMPEG_ARCH}
    --cpu=${FFMPEG_CPU}
    --enable-cross-compile
    --cross-prefix=${FFMPEG_CROSS_PREFIX}
    --sysroot=${NDK_TOOLCHAIN}/sysroot
    --cc=${FFMPEG_CC}
    --enable-shared
    --disable-static
    --enable-gpl
    --enable-version3
    --enable-nonfree

    --enable-protocol=all
    --enable-demuxer=all
    --enable-muxer=all
    --enable-parser=all
    --enable-decoder=all
    --enable-encoder=all
    --enable-filter=all
    --extra-cflags=-fPIC
    "--extra-ldflags=-fuse-ld=lld -Wl,--gc-sections -Wl,-z,max-page-size=${MAX_PAGE_SIZE}"
    --ar=${NDK_TOOLCHAIN}/bin/llvm-ar
    --ranlib=${NDK_TOOLCHAIN}/bin/llvm-ranlib
    --nm=${NDK_TOOLCHAIN}/bin/llvm-nm
    --strip=${NDK_TOOLCHAIN}/bin/llvm-strip
  BUILD_COMMAND     make -j${CMAKE_JOB_POOL_DEFAULT}
  INSTALL_COMMAND   make install
)

# Collect .so into output/<ABI>
add_custom_command(TARGET ffmpeg POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
        "${CMAKE_BINARY_DIR}/output/${CMAKE_ANDROID_ARCH_ABI}"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${FFMPEG_INSTALL_DIR}/lib"
        "${CMAKE_BINARY_DIR}/output/${CMAKE_ANDROID_ARCH_ABI}"
)

add_custom_target(collect ALL DEPENDS ffmpeg)
