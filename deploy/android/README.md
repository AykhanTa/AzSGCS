# Android deployment

## DTED elevation tiles

Offline elevation uses the DTED tiles in `resources/dted` (~619 MB). Desktop
builds compile them into the executable. Android does not: an `.so` that large
is impractical to ship and to map, so the tiles are copied to the device once
and the app finds them there.

`LocalDtedElevation::dtedSearchDirs()` looks in this order, first hit per file
name wins:

1. `$QGC_DTED_PATH` — explicit override, e.g. an SD card
2. `<AppDataLocation>/dted` — **the Android location**
3. `<app dir>/dted` — portable desktop install
4. `:/dted` — compiled in (desktop only)

On Android `AppDataLocation` resolves to:

```
/sdcard/Android/data/org.mavlink.qgroundcontrol/files/dted
```

Substitute the real package name if `QGC_ANDROID_PACKAGE_NAME` was changed.

### Copying the tiles

Run the app once first, so Android creates the directory.

```sh
adb shell mkdir -p /sdcard/Android/data/org.mavlink.qgroundcontrol/files/dted
adb push resources/dted/. /sdcard/Android/data/org.mavlink.qgroundcontrol/files/dted/
```

That pushes ~619 MB and takes a few minutes over USB. Only `.dt2` files are
read; `dted.qrc` can be pushed too, it is ignored.

### Checking it worked

```sh
adb logcat -s AzShieldGCS | grep -i dted
```

Expect `Loaded 25 DTED elevation tiles`. If instead you see
`No DTED (.dt2) tiles found. Searched: ...`, the listed paths are exactly what
the app tried — compare them against where the files actually landed. The usual
cause is a package name mismatch in the destination path.

Coverage is E44–E48 / N38–N41. Outside that box elevation falls back to the
configured online provider.

## Building

Prerequisites: Qt 6.11.1 `android_arm64_v8a` plus a host kit, JDK 17, Android
SDK with platform 36 and build-tools, and NDK **r27c** (`ndk;27.2.12479018`).
The NDK version is not a preference: Qt's prebuilt Android libraries are built
against it and carry its libc++, so `cmake/platform/Android.cmake` rejects
anything else.

### The SDK and NDK paths must not contain spaces

This is worth stating plainly because the failure is a long way from the cause.
With an SDK under, say, `C:\Users\First Last\AppData\Local\Android\Sdk`:

- CMake's Ninja generator cannot put a path with a space in the compiler slot,
  so it writes the 8.3 short form, `CLANG_~1.EXE` under `WINDOW~1`.
- Clang decides whether to add its own NDK library directories by comparing the
  `--sysroot` it was handed against its own install directory. One is short and
  one is long, so the comparison fails and it adds neither.
- `usr/lib/aarch64-linux-android/<api>/libc++.so` -- a linker script that reads
  `INPUT(-lc++_shared)`, and the only route to the STL -- is therefore never on
  the search path.
- Everything compiles. The link then fails on `operator new`, `__cxa_guard_*`
  and every `__cxxabiv1` vtable, as though the project had no C++ runtime.

Note that a short compiler path alone is harmless, and an explicit `--sysroot`
alone is harmless. It takes both.

Junctions are enough to fix it and copy nothing:

```bat
mklink /J "C:\Android\Sdk" "%LOCALAPPDATA%\Android\Sdk"
mklink /J "C:\Android\ndk\27.2.12479018" "C:\Android\Sdk\ndk\27.2.12479018"
```

Then configure and build through those paths:

```sh
export ANDROID_SDK_ROOT=C:/Android/Sdk
export ANDROID_NDK_ROOT=C:/Android/ndk/27.2.12479018
export JAVA_HOME="C:/Program Files/Java/jdk-17"

C:/Qt/6.11.1/android_arm64_v8a/bin/qt-cmake.bat -S . -B build-android-arm64 \
    -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DQT_HOST_PATH=C:/Qt/6.11.1/mingw_64 \
    -DANDROID_SDK_ROOT=C:/Android/Sdk \
    -DANDROID_NDK_ROOT=C:/Android/ndk/27.2.12479018
cmake --build build-android-arm64 --parallel
```

To check the paths came out clean: `grep -c '~1' build-android-arm64/build.ninja`
should print 0.

### Signing

The build leaves `android-build/AzShieldGCS.apk` unsigned, and Android will not
install it. For a test install the debug key is enough:

```sh
BT=C:/Android/Sdk/build-tools/36.1.0
$BT/zipalign.exe -p -f 4 AzShieldGCS.apk AzShieldGCS-aligned.apk
$BT/apksigner.bat sign --ks ~/.android/debug.keystore \
    --ks-pass pass:android --ks-key-alias androiddebugkey --key-pass pass:android \
    --out AzShieldGCS-signed.apk AzShieldGCS-aligned.apk
$BT/apksigner.bat verify -v AzShieldGCS-signed.apk
```

A release build wants its own keystore, via `QT_ANDROID_SIGN_APK` and the
`QT_ANDROID_KEYSTORE_*` variables, rather than the debug key.
