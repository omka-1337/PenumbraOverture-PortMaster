#!/usr/bin/env bash
# Assembles build-arm64/penumbra.zip, the package PortMaster installs, from
# what build-arm64.sh and build-openal-arm64.sh produced. The layout is the one
# port/README.md describes, minus the game data, which the player supplies.
set -euo pipefail

cd "$(dirname "$0")"

STAGE=build-arm64/package
ZIP=build-arm64/penumbra.zip

for f in build-arm64/PenumbraOverture build-arm64/libs/libopenal.so.1; do
	if [ ! -f "$f" ]; then
		echo "No $f. Run ./build-arm64.sh and ./build-openal-arm64.sh first." >&2
		exit 1
	fi
done
if ! ls rehatched/core/programs/* >/dev/null 2>&1; then
	echo "No shaders in rehatched/core/programs. Run ./build-arm64.sh first." >&2
	exit 1
fi

rm -rf "$STAGE" "$ZIP"
mkdir -p "$STAGE/penumbra/libs"

cp "port/Penumbra Overture.sh" "$STAGE/"
cp build-arm64/PenumbraOverture port/penumbra.gptk LICENSE NOTICE \
	"$STAGE/penumbra/"
cp build-arm64/libs/libopenal.so.1 "$STAGE/penumbra/libs/"

# Only what git tracks under rehatched/, plus the shaders cmake copies in.
# A working copy can hold retail textures and sounds dropped there as local
# overrides, which .gitignore keeps out of the repository and this keeps out of
# the package. scripts/ is zenmumbler's material-checking tool, not game data.
git ls-files -z rehatched ':!rehatched/scripts' |
	tar --null -T - -cf - | tar -C "$STAGE/penumbra" -xf -
mkdir -p "$STAGE/penumbra/rehatched/core/programs"
cp rehatched/core/programs/* "$STAGE/penumbra/rehatched/core/programs/"

(cd "$STAGE" && zip -qr -X ../penumbra.zip "Penumbra Overture.sh" penumbra)

echo "$ZIP"
unzip -l "$ZIP" | tail -1
