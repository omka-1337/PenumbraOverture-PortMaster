#!/usr/bin/env bash
# Builds the libopenal.so.1 that ships in the port's libs/, inside the same
# PortMaster container as the game.
#
# The container's own libopenal1 cannot ship: Ubuntu builds it against sndio,
# so it needs libsndio.so.7.0, which the handheld firmwares do not carry. Built
# here, every audio backend is dlopened at runtime instead, so the library
# needs nothing beyond libc and libstdc++ and plays through whichever of ALSA
# or PulseAudio the device has.
#
# Needs arm64 emulation registered on the host, as build-arm64.sh does.
set -eu

cd "$(dirname "$0")"

# Pinned to the commit rather than the tag, so a moved tag cannot change what
# ships. 1.23.1 is the last release that wants only C++14.
OPENAL_VERSION=1.23.1
OPENAL_COMMIT=d3875f333fb6abe2f39d82caca329414871ae53b

SRC=build-arm64/openal-soft-$OPENAL_VERSION
OUT=build-arm64/libs/libopenal.so.1

if [ "$(git -C "$SRC" rev-parse HEAD 2>/dev/null)" != "$OPENAL_COMMIT" ]; then
	echo "fetching OpenAL Soft $OPENAL_VERSION..."
	rm -rf "$SRC"
	git init -q "$SRC"
	git -C "$SRC" fetch -q --depth 1 https://github.com/kcat/openal-soft "$OPENAL_COMMIT"
	git -C "$SRC" -c advice.detachedHead=false checkout -q FETCH_HEAD
fi

docker build -q -f Dockerfile.arm64 -t penumbra-arm64-builder . >/dev/null

# The REQUIRE switches turn a missing backend into a configure error. Without
# them OpenAL quietly builds with neither, and the game then runs in silence.
#
# The NEEDED check at the end is the point of the exercise: anything past the
# C and C++ runtimes is a library the device may not have.
docker run --rm --platform linux/arm64 \
	-v "$PWD":/src \
	-u "$(id -u):$(id -g)" \
	penumbra-arm64-builder \
	bash -lc '
		set -e
		cmake -S /src/'"$SRC"' -B /src/'"$SRC"'/build -DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_C_COMPILER=gcc-10 -DCMAKE_CXX_COMPILER=g++-10 \
			-DALSOFT_UTILS=OFF -DALSOFT_EXAMPLES=OFF -DALSOFT_INSTALL=OFF \
			-DALSOFT_BACKEND_SNDIO=OFF \
			-DALSOFT_REQUIRE_ALSA=ON -DALSOFT_REQUIRE_PULSEAUDIO=ON >/dev/null
		cmake --build /src/'"$SRC"'/build -j'"$(nproc)"'

		lib=/src/'"$SRC"'/build/libopenal.so.1
		extra=$(readelf -d "$lib" | sed -n "s/.*NEEDED.*\[\(.*\)\]/\1/p" |
			grep -Ev "^(libc|libm|libdl|libpthread|librt|libstdc\+\+|libgcc_s|ld-linux-aarch64)\.so" || true)
		if [ -n "$extra" ]; then
			echo "libopenal.so.1 links libraries the devices may not have:" >&2
			echo "$extra" >&2
			exit 1
		fi
	'

mkdir -p "$(dirname "$OUT")"
cp -L "$SRC/build/libopenal.so.1" "$OUT"

echo
file "$OUT" 2>/dev/null | cut -c1-100
