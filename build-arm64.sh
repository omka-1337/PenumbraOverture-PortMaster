#!/usr/bin/env bash
# Builds the aarch64 binary inside the PortMaster container.
# Needs arm64 emulation registered on the host:
#   docker run --privileged --rm tonistiigi/binfmt --install arm64
set -eu

cd "$(dirname "$0")"

ENGINE_DIR=${HPL1_ENGINE_DIR:-$PWD/../../HPL1-Fledged}
if [ ! -f "$ENGINE_DIR/CMakeLists.txt" ]; then
	echo "HPL1 engine not found at $ENGINE_DIR" >&2
	echo "Set HPL1_ENGINE_DIR to point at it." >&2
	exit 1
fi
ENGINE_DIR=$(cd "$ENGINE_DIR" && pwd)

docker build -q -f Dockerfile.arm64 -t penumbra-arm64-builder . >/dev/null

# The engine lives outside this directory, so it is mounted separately.
# The build tree is kept apart from the desktop one so the two never mix.
docker run --rm --platform linux/arm64 \
	-v "$PWD":/src \
	-v "$ENGINE_DIR":/engine \
	-u "$(id -u):$(id -g)" \
	penumbra-arm64-builder \
	bash -lc '
		cmake -S /src -B /src/build-arm64 -DCMAKE_BUILD_TYPE=Release \
			-DHPL1_ENGINE_DIR=/engine \
			-DCMAKE_C_COMPILER=gcc-10 -DCMAKE_CXX_COMPILER=g++-10 &&
		cmake --build /src/build-arm64 -j'"$(nproc)"'
	'

echo
file build-arm64/PenumbraOverture 2>/dev/null | cut -c1-100
