# ffmpeg-android-minimal

---

**Minimal FFmpeg `.so` builds for Android**, focused on audio conversion — with support for both **4 KB** and **16 KB** memory page-size devices, built entirely in CI and published as downloadable artifacts.

> 🎯 A standalone build repo: clone, build, grab the `.so` files, and drop them into your own Android app.

---

## 🚀 Features

- ✅ Converts audio formats (e.g. `.webm` → `.mp3`)  
- ✅ Shared `.so` libraries for Android ABIs (`arm64-v8a`, `armeabi-v7a`, …)  
- ✅ Built with Android NDK r27+ **flexible page-size** support (4 KB & 16 KB)  
- ✅ GitHub Actions workflow — zero local setup  
- ✅ CI artifacts can be pulled by your app’s pipeline  

---

## 📦 Built Libraries

```text
output/
├── arm64-v8a/
│   ├── libavcodec.so
│   ├── libavformat.so
│   └── libavutil.so
└── armeabi-v7a/
    ├── libavcodec.so
    ├── libavformat.so
    └── libavutil.so
````

---

## 🛠️ How the `.so` Files Are Built

1. **Clone FFmpeg** on-the-fly in CI (no `ffmpeg/` in this repo).
2. **CMake** + Android toolchain (r27+), with

   * `-DANDROID_PLATFORM=android-21`
   * `-DANDROID_ABI=arm64-v8a;armeabi-v7a`
   * `-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON`
   * `-DCMAKE_SHARED_LINKER_FLAGS="-Wl,-z,max-page-size=16384"`
3. **Build** via `cmake --build .` → produces `*.so` in `output/<ABI>/`.
4. **Verify** ELF `p_align` via `readelf` (4 KB & 16 KB compatibility).
5. **Upload** artifacts to GitHub Actions.

> ✔️ All steps automated in [`.github/workflows/build.yml`](.github/workflows/build.yml).

---

## 📲 How to Use in Your Android Project

1. **Download** the `.so` artifacts from the GitHub Actions build.
2. **Copy** into your app’s `app/src/main/jniLibs/<ABI>/` folders.
3. **Load** in code before any FFmpeg calls:

   ```kotlin
   System.loadLibrary("avutil")
   System.loadLibrary("avformat")
   System.loadLibrary("avcodec")
   ```
4. **Call** FFmpeg via your own JNI bridge or command-line wrapper.

---

## 📂 Project Structure

```
/
├── CMakeLists.txt
├── cmake/
│   └── AndroidFlexPages.cmake
├── scripts/
│   └── fetch-ffmpeg.sh
├── .github/
│   └── workflows/
│       └── build.yml
├── README.md
└── LICENSE
```

* **`CMakeLists.txt`** – configures FFmpeg as an ExternalProject, applies flexible page flags
* **`cmake/AndroidFlexPages.cmake`** – sets `ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES` & linker flags
* **`scripts/fetch-ffmpeg.sh`** – clones or updates the FFmpeg Git repo on demand
* **`.github/workflows/build.yml`** – CI steps: setup NDK → clone FFmpeg → CMake → build → verify → publish

---

## 🌱 Roadmap

* [ ] JNI helper library for simpler integration
* [ ] Support additional codecs & formats
* [ ] Extend to video and subtitle modules
* [ ] Publish versioned releases on GitHub Releases

---

## 📄 License

This repo contains only build scripts and configuration.
**FFmpeg** remains under its [LGPL/GPL](https://ffmpeg.org/legal.html) licenses.

---

## 🙌 Contributing

PRs and issues welcome! Feel free to suggest new codecs, improve CI, or add usage examples.
