#!/usr/bin/env bash
# Pushes what this repository builds to the device over ssh: the aarch64
# binary, the shaders, the launch script and the pad mapping. The game data is
# not touched, because it is the player's own copy and it never changes.
#
# scp rather than rsync: scp ships with ssh, and a dev machine that has one
# does not necessarily have the other.
#
# The device address moves with DHCP, so it is a variable rather than a
# constant:
#   PENUMBRA_DEVICE=root@192.168.1.50 ./deploy.sh
set -eu

cd "$(dirname "$0")"

DEVICE=${PENUMBRA_DEVICE:-root@192.168.100.73}
PORTS=${PENUMBRA_PORTS:-/roms/ports}
REMOTE="$PORTS/penumbra"

if [ ! -f build-arm64/PenumbraOverture ]; then
	echo "No aarch64 binary. Run ./build-arm64.sh first." >&2
	exit 1
fi

# The card is exFAT, which carries no exec bit, so the launch script chmods the
# binary at startup. Nothing to preserve here beyond the bytes.
echo "binary..."
scp -q build-arm64/PenumbraOverture "$DEVICE:$REMOTE/PenumbraOverture"

# The shaders are the half most likely to be stale: they are data the engine
# compiles at runtime, so a mismatched one fails quietly rather than loudly.
# Clearing the directory first means a shader deleted here goes away there.
echo "shaders..."
ssh "$DEVICE" "mkdir -p '$REMOTE/rehatched/core/programs' && rm -f '$REMOTE/rehatched/core/programs/'*"
scp -q rehatched/core/programs/* "$DEVICE:$REMOTE/rehatched/core/programs/"

echo "launcher..."
scp -q port/penumbra.gptk "$DEVICE:$REMOTE/penumbra.gptk"
scp -q "port/Penumbra Overture.sh" "$DEVICE:$PORTS/"

echo
echo "deployed to $DEVICE:$REMOTE"
