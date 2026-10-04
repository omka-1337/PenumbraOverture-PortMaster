#!/usr/bin/env bash
# Grabs one frame without anyone having to drive the game.
#
# The game reads its settings from the user profile, not from run/config, and
# rewrites that file on exit - so the profile is swapped out for the run and
# put back afterwards, including if the run is killed.
#
#   ./capture.sh <frame> <out.ppm> [map.dae] [startpos]
set -u

FRAME=${1:-1200}
OUT=${2:-/tmp/frame.ppm}
MAP=${3:-level00_01_boat_cabin.dae}
POS=${4:-link1}

SETTINGS="$HOME/.frictionalgames/Penumbra/Overture/settings.cfg"
BACKUP=$(mktemp)

restore() {
	[ -s "$BACKUP" ] && cp "$BACKUP" "$SETTINGS"
	rm -f "$BACKUP"
}
trap restore EXIT INT TERM

cd "$(dirname "$0")"
[ build/PenumbraOverture -nt run/PenumbraOverture ] && { rm -f run/PenumbraOverture; cp build/PenumbraOverture run/PenumbraOverture; }

cp "$SETTINGS" "$BACKUP"
sed -i 's|ShowPreMenu="[^"]*"|ShowPreMenu="false"|; s|ShowMenu="[^"]*"|ShowMenu="false"|; s|ShowIntro="[^"]*"|ShowIntro="false"|' "$SETTINGS"
sed -i "s|File=\"[^\"]*\.dae\"|File=\"$MAP\"|; s|StartPos=\"[^\"]*\"|StartPos=\"$POS\"|" "$SETTINGS"

( cd run && HPL_SCREENSHOT="$FRAME:$OUT" timeout -s KILL 120 ./PenumbraOverture >/dev/null 2>&1 )

[ -f "$OUT" ] && echo "знято: $OUT" || echo "кадр не знято"
