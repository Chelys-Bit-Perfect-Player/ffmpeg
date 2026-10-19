#!/bin/bash
# Builds the FFmpeg libraries in Chelys for Android (arm64-v8a) into ./out/android, with the exact settings Chelys uses:
# a minimal, LGPL, audio-only FFmpeg. Needs the Android NDK (Chelys uses 27.1.12297006) and a macOS host.
set -euo pipefail

VERSION=8.0
API=29
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$HERE/build/android"
OUT="$HERE/out/android"
NDK="${ANDROID_NDK:-$HOME/Library/Android/sdk/ndk/27.1.12297006}"
TC="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin"
SOURCE="https://github.com/Chelys-Bit-Perfect-Player/ffmpeg/releases/download/ffmpeg-$VERSION/ffmpeg-$VERSION.tar.xz"

mkdir -p "$WORK"
cd "$WORK"
[ -d "ffmpeg-$VERSION" ] || curl -sfL "$SOURCE" | tar xJ
cd "ffmpeg-$VERSION"

./configure \
  --prefix="$WORK/install" \
  --target-os=android --arch=aarch64 --cpu=armv8-a --enable-cross-compile \
  --cc="$TC/aarch64-linux-android$API-clang" --cxx="$TC/aarch64-linux-android$API-clang++" \
  --ar="$TC/llvm-ar" --nm="$TC/llvm-nm" --ranlib="$TC/llvm-ranlib" --strip="$TC/llvm-strip" \
  --enable-shared --disable-static --enable-pic \
  --disable-programs --disable-doc --disable-avdevice --disable-avfilter --disable-swscale \
  --disable-network --disable-everything \
  --enable-protocol=file \
  --enable-demuxer=flac,mov,wav,aiff,dsf,iff,mp3,aac,ogg,matroska,w64,ape,wv,asf,mpc,mpc8,tta,tak,caf \
  --enable-decoder=flac,alac,ape,wavpack,mp3float,mp3,aac,vorbis,opus,mjpeg,png,wmav1,wmav2,wmapro,wmalossless,mpc7,mpc8,tta,tak \
  --enable-decoder='dsd_lsbf,dsd_msbf,dsd_lsbf_planar,dsd_msbf_planar,pcm_s16le,pcm_s16be,pcm_s24le,pcm_s24be,pcm_s32le,pcm_s32be,pcm_f32le,pcm_f32be,pcm_u8' \
  --enable-parser=flac,mpegaudio,aac,opus,vorbis,tak \
  --enable-swresample \
  --extra-ldflags="-Wl,-z,max-page-size=16384"

# Android loads libraries by plain name: drop the versioned SONAMEs (libavcodec.so.62 -> libavcodec.so).
sed -i '' \
  -e 's/^SLIBNAME_WITH_MAJOR=.*/SLIBNAME_WITH_MAJOR=$(SLIBNAME)/' \
  -e 's/^SLIB_INSTALL_NAME=.*/SLIB_INSTALL_NAME=$(SLIBNAME)/' \
  -e 's/^SLIB_INSTALL_LINKS=.*/SLIB_INSTALL_LINKS=/' \
  ffbuild/config.mak

make -j"$(sysctl -n hw.ncpu)"
make install

rm -rf "$OUT"
mkdir -p "$OUT/lib/arm64-v8a"
cp -R "$WORK/install/include" "$OUT/include"
for l in avformat avcodec avutil swresample; do
  "$TC/llvm-strip" --strip-unneeded -o "$OUT/lib/arm64-v8a/lib$l.so" "$WORK/install/lib/lib$l.so"
done
echo "FFmpeg $VERSION for Android in $OUT"
