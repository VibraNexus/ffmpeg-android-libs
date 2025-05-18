cmake_minimum_required(VERSION 3.14)
project(ffmpeg_android_minimal NONE)
message(STATUS "CMake version: ${CMAKE_VERSION}")
message(STATUS "Android NDK: ${CMAKE_ANDROID_NDK}")

# Ensure this is an Android cross‑compile
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Android")
  message(FATAL_ERROR "This project must be built with the Android NDK toolchain (use -DCMAKE_TOOLCHAIN_FILE).")
endif()

# Pull in module to enable flexible page sizes and set linker flags
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(AndroidFlexPages)
message(STATUS "Flexible page sizes: ${ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES}, max-page-size=${MAX_PAGE_SIZE}")

# ExternalProject to fetch & build FFmpeg
include(ExternalProject)

# Variables
set(FFMPEG_GIT_REPO "https://github.com/FFmpeg/FFmpeg.git")
set(FFMPEG_GIT_TAG "master")  # pin to a release or commit if desired
set(FFMPEG_SOURCE_DIR "${CMAKE_BINARY_DIR}/ffmpeg-src")
set(FFMPEG_INSTALL_DIR "${CMAKE_BINARY_DIR}/ffmpeg-install")

# Determine FFmpeg configure triples based on ABI
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

# Paths to NDK toolchain
set(NDK_TOOLCHAIN "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/${CMAKE_HOST_SYSTEM_NAME}-${CMAKE_HOST_SYSTEM_PROCESSOR}")
set(FFMPEG_CROSS_PREFIX "${NDK_TOOLCHAIN}/bin/${FFMPEG_TARGET_HOST}-")
set(FFMPEG_CC "${NDK_TOOLCHAIN}/bin/${FFMPEG_TARGET_HOST}${CMAKE_SYSTEM_VERSION}-clang")

message(STATUS "Configuring ExternalProject ffmpeg...")
ExternalProject_Add(ffmpeg
  PREFIX               ${CMAKE_BINARY_DIR}/ffmpeg
  GIT_REPOSITORY       ${FFMPEG_GIT_REPO}
  GIT_TAG              ${FFMPEG_GIT_TAG}
  SOURCE_DIR           ${FFMPEG_SOURCE_DIR}
  BINARY_DIR           ${FFMPEG_SOURCE_DIR}/build
  INSTALL_DIR          ${FFMPEG_INSTALL_DIR}
  UPDATE_COMMAND       ""
  CONFIGURE_COMMAND ${FFMPEG_SOURCE_DIR}/configure
      --prefix=${FFMPEG_INSTALL_DIR}  
      --target-os=android            
      --arch=${FFMPEG_ARCH}          
      --cpu=${FFMPEG_CPU}            
      --enable-cross-compile         
      --cross-prefix=${FFMPEG_CROSS_PREFIX} 
      --sysroot=${NDK_TOOLCHAIN}/sysroot 
      --cc=${FFMPEG_CC}              
      --disable-everything           
      --enable-small                 
      --enable-shared                
      --disable-static               
      --extra-cflags="-fPIC"        
      --extra-ldflags="-fuse-ld=lld -Wl,--gc-sections -Wl,-z,max-page-size=${MAX_PAGE_SIZE}" 
      --enable-protocol=file         
      --enable-decoder=opus,vorbis,aac  
      --enable-encoder=mp3,flac,aac      
      --enable-demuxer=webm,matroska,ogg 
      --enable-muxer=mp3,flac,ipod       
  BUILD_COMMAND        make -j${CMAKE_JOB_POOL_DEFAULT} 
    WORKING_DIRECTORY   ${FFMPEG_SOURCE_DIR}/build
  INSTALL_COMMAND      make install      
    WORKING_DIRECTORY   ${FFMPEG_SOURCE_DIR}/build
)

# After install, collect libraries into output/<ABI>/
add_custom_command(TARGET ffmpeg POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/output/${CMAKE_ANDROID_ARCH_ABI}"
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${FFMPEG_INSTALL_DIR}/lib"
    "${CMAKE_BINARY_DIR}/output/${CMAKE_ANDROID_ARCH_ABI}"
)
add_custom_target(collect ALL DEPENDS ffmpeg)
