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
