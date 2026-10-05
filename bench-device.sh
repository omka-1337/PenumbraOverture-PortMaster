#!/usr/bin/env bash
# Measures the frame rate on the device, inside an actual level.
#
# The menu tells you nothing about how the renderer performs, and nobody can
# hold a controller steady enough for an A/B anyway, so this writes a profile
# that skips the menus and drops straight into a map, runs for a fixed time
# with the engine logging its frame rate, then takes the profile away again.
#
#   ./bench-device.sh                                  # default map, defaults
#   ./bench-device.sh level01_14_refinery.dae
#   HPL_ENV="HPL_SHADOW_BUDGET=0" ./bench-device.sh     # one knob changed
set -eu

cd "$(dirname "$0")"

MAP=${1:-level00_01_boat_cabin.dae}
POS=${2:-link1}
SECONDS_TO_RUN=${BENCH_SECONDS:-45}
EXTRA_ENV=${HPL_ENV:-}

DEVICE=${PENUMBRA_DEVICE:-root@192.168.100.73}
REMOTE=${PENUMBRA_REMOTE:-/roms/ports/penumbra}
PROFILE="$REMOTE/.frictionalgames/Penumbra/Overture"

SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

# The panel is 640x480, so measure at 640x480. A benchmark at the desktop's
# resolution would answer a question nobody asked.
sed -e 's|ShowPreMenu="[^"]*"|ShowPreMenu="false"|' \
    -e 's|ShowMenu="[^"]*"|ShowMenu="false"|' \
    -e 's|ShowIntro="[^"]*"|ShowIntro="false"|' \
    -e 's|Width="[^"]*"|Width="640"|' \
    -e 's|Height="[^"]*"|Height="480"|' \
    -e 's|FullScreen="[^"]*"|FullScreen="true"|' \
    -e "s|File=\"[^\"]*\.dae\"|File=\"$MAP\"|" \
    -e "s|StartPos=\"[^\"]*\"|StartPos=\"$POS\"|" \
    run/config/default_settings.cfg > "$SCRATCH/settings.cfg"

# Keep whatever the player had. Deleting it instead of restoring it loses
# their resolution and key bindings, and the game only writes the file on a
# clean exit, so it does not come back by itself.
ssh "$DEVICE" "[ -f '$PROFILE/settings.cfg' ] && cp '$PROFILE/settings.cfg' '$PROFILE/settings.cfg.bench-backup' || true"

scp -q "$SCRATCH/settings.cfg" "$DEVICE:$PROFILE/settings.cfg"

echo "running $MAP for ${SECONDS_TO_RUN}s on $DEVICE ${EXTRA_ENV:+with $EXTRA_ENV}"

# The game is started the way the launch script starts it, minus gptokeyb:
# nothing here presses a button, so the pad would only get in the way.
ssh "$DEVICE" "
	cd '$REMOTE' || exit 1
	rm -f '$PROFILE/hpl.log'
	export WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/var/run/0-runtime-dir
	export SDL_VIDEODRIVER=wayland SDL_AUDIODRIVER=pulseaudio
	export HOME='$REMOTE'
	export LD_LIBRARY_PATH='$REMOTE/libs':\$LD_LIBRARY_PATH
	export HPL_FPS_LOG=5
	$EXTRA_ENV
	chmod +x ./PenumbraOverture
	timeout -s KILL $SECONDS_TO_RUN ./PenumbraOverture >/dev/null 2>&1
	true
"

scp -q "$DEVICE:$PROFILE/hpl.log" "$SCRATCH/hpl.log" 2>/dev/null || true

# Put the player's own profile back, or clear ours if there was none.
ssh "$DEVICE" "
	if [ -f '$PROFILE/settings.cfg.bench-backup' ]; then
		mv '$PROFILE/settings.cfg.bench-backup' '$PROFILE/settings.cfg'
	else
		rm -f '$PROFILE/settings.cfg'
	fi"

# The first interval covers loading, so it is dropped: it measures the disk,
# not the renderer.
awk '/FPS /{ n++; if (n > 1) print $2 }' "$SCRATCH/hpl.log" \
| sort -n \
| awk -v map="$MAP" '
	{ v[NR] = $1; sum += $1 }
	END {
		if (NR == 0) { print "no frame rate logged - did the game start?"; exit 1 }
		med = (NR % 2) ? v[(NR+1)/2] : (v[NR/2] + v[NR/2+1]) / 2
		printf "%s: median %.1f fps (%.1f ms), min %.1f, max %.1f, over %d samples\n",
			map, med, (med > 0 ? 1000/med : 0), v[1], v[NR], NR
	}'
