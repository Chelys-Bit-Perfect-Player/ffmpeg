# FFmpeg in Chelys

Chelys, a bit-perfect music player for Android and macOS, decodes audio with [FFmpeg](https://ffmpeg.org), which is
licensed under the GNU Lesser General Public License, version 2.1 or later. This repository is the corresponding
source for the FFmpeg libraries that Chelys ships, as that license requires.

## What Chelys ships

- **FFmpeg 8.0, unmodified.** The exact source is attached to the
  [ffmpeg-8.0 release](https://github.com/Chelys-Bit-Perfect-Player/ffmpeg/releases/tag/ffmpeg-8.0) as
  `ffmpeg-8.0.tar.xz`, identical to the archive published at ffmpeg.org:
  SHA-256 `b2751fccb6cc4c77708113cd78b561059b6fa904b24162fa0be2d60273d27b8e`.
- **Four shared libraries:** libavformat, libavcodec, libavutil and libswresample.
- **LGPL only.** Built without `--enable-gpl`, `--enable-version3` or `--enable-nonfree`, and with only the audio
  demuxers, decoders and parsers Chelys needs.
- **Build settings:** [`build-android.sh`](build-android.sh) (arm64-v8a, Android API 29, NDK 27.1.12297006) and
  [`build-macos.sh`](build-macos.sh) (Apple silicon, macOS 14). Each builds into `out/`.

## Using your own FFmpeg

Chelys loads these libraries by name and does not check them, so you can replace them with your own build of
FFmpeg 8.x. Changes that keep the 8.0 interface (libavformat 62, libavcodec 62, libavutil 60, libswresample 6) will
work.

- **Android:** the libraries are in the APK under `lib/arm64-v8a/`. Replace `libavformat.so`, `libavcodec.so`,
  `libavutil.so` and `libswresample.so`, sign the APK with your own key, and install it. An APK signed with a
  different key can't update the store version, so uninstall that first.
- **macOS:** the libraries are in `Chelys.app/Contents/Frameworks/`, under their versioned names
  (`libavformat.62.dylib` and so on). Replace them, then sign the app again, for example with
  `codesign --force --deep --sign - Chelys.app`.

## License

FFmpeg is licensed under the LGPL 2.1 or later; its text is in [`COPYING.LGPLv2.1`](COPYING.LGPLv2.1). The build
scripts here are offered under the same license. Chelys itself is not part of this repository.
