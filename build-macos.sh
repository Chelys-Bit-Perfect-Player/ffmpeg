#!/bin/bash
# Builds the FFmpeg libraries in Chelys for macOS (Apple silicon) into ./out/macos, with the exact settings Chelys uses:
# the same minimal, LGPL, audio-only FFmpeg as build-android.sh, as dylibs.
set -euo pipefail

VERSION=8.0
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$HERE/build/macos"
OUT="$HERE/out/macos"
SOURCE="https://github.com/Chelys-Bit-Perfect-Player/ffmpeg/releases/download/ffmpeg-$VERSION/ffmpeg-$VERSION.tar.xz"

mkdir -p "$WORK"
cd "$WORK"
[ -d "ffmpeg-$VERSION" ] || curl -sfL "$SOURCE" | tar xJ
cd "ffmpeg-$VERSION"

# No autodetection: nothing from Homebrew may end up linked. zlib comes with macOS (PNG cover art).
./configure \
  --prefix="$WORK/install" \
  --arch=arm64 --cc=clang \
  --extra-cflags="-mmacosx-version-min=14.0" --extra-ldflags="-mmacosx-version-min=14.0" \
  --enable-shared --disable-static --install-name-dir='@rpath' \
  --disable-autodetect --enable-zlib \
  --disable-programs --disable-doc --disable-avdevice --disable-avfilter --disable-swscale \
  --disable-network --disable-everything \
  --enable-protocol=file \
  --enable-demuxer=flac,mov,wav,aiff,dsf,iff,mp3,aac,ogg,matroska,w64,ape,wv,asf,mpc,mpc8,tta,tak,caf \
  --enable-decoder=flac,alac,ape,wavpack,mp3float,mp3,aac,vorbis,opus,mjpeg,png,wmav1,wmav2,wmapro,wmalossless,mpc7,mpc8,tta,tak \
  --enable-decoder='dsd_lsbf,dsd_msbf,dsd_lsbf_planar,dsd_msbf_planar,pcm_s16le,pcm_s16be,pcm_s24le,pcm_s24be,pcm_s32le,pcm_s32be,pcm_f32le,pcm_f32be,pcm_u8' \
  --enable-parser=flac,mpegaudio,aac,opus,vorbis,tak \
  --enable-swresample

make -j"$(sysctl -n hw.ncpu)"
make install

# Each dylib keeps its install name (libavformat.62.dylib), which is how the app bundle carries it.
rm -rf "$OUT"
mkdir -p "$OUT/lib"
cp -R "$WORK/install/include" "$OUT/include"
for l in avformat avcodec avutil swresample; do
  name="$(basename "$(otool -D "$WORK/install/lib/lib$l.dylib" | tail -1)")"
  strip -x -o "$OUT/lib/$name" "$WORK/install/lib/lib$l.dylib"
done
echo "FFmpeg $VERSION for macOS in $OUT"
