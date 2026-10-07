#!/bin/bash
# PORTMASTER: penumbra.zip, Penumbra Overture.sh

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
elif [ -d "/storage/roms/ports/PortMaster/" ]; then
  controlfolder="/storage/roms/ports/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
source $controlfolder/device_info.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

PORTS_DIR="/$directory/ports"
GAME_DIR="${PORTS_DIR}/penumbra"

# $directory is whatever control.txt decided, and it is not the same everywhere.
# Fall back rather than carry on in the wrong place: everything below is
# relative to this, so a wrong guess here fails in confusing ways much later.
if [ ! -d "$GAME_DIR" ]; then GAME_DIR="/roms/ports/penumbra"; fi
if [ ! -d "$GAME_DIR" ]; then GAME_DIR="/storage/roms/ports/penumbra"; fi
if [ ! -d "$GAME_DIR" ]; then
  echo "ERROR: cannot find the penumbra folder under /$directory/ports, /roms/ports or /storage/roms/ports"
  exit 1
fi

LOG_FILE="${GAME_DIR}/log.txt"
cd "$GAME_DIR" || exit 1

exec > >(tee "$LOG_FILE") 2>&1

$ESUDO chmod 666 /dev/uinput
chmod +x "$GAME_DIR/PenumbraOverture"

# Only OpenAL is carried along; SDL2 and GLES come from the system.
export LD_LIBRARY_PATH="$GAME_DIR/libs:$LD_LIBRARY_PATH"

# The engine keeps settings and saves under $HOME, which must be writable. Its
# own folder rather than the game folder, so the saves are not mixed in with the
# player's copy of the game, and XDG is pointed at it too or it would still
# refer to the real home from before this line.
export HOME="$GAME_DIR/home"
mkdir -p "$HOME/.local/share"
export XDG_DATA_HOME="$HOME/.local/share"

# The stick on this device reports no tilt, only on or off, so one speed has to
# serve both landing on an inventory slot and turning round, and no single speed
# does. The base speed is set in penumbra.gptk (mouse_scale); this is the ramp
# on top of it, as <top speed>:<how fast it gets there>:<starting speed>. So a
# short push moves at the base speed and a push you hold climbs to three times
# that over about a second, dropping back when you let go. Lower the middle
# number if the change of speed is itself noticeable: the pointer moves once per
# drawn frame, so a gain that climbs quickly reads as surging.
export HPL_MOUSE_ACCEL=3:2:1

# HPL_PARTICLE_SCALE thins every particle system, and the outdoor snowfall is
# what it exists for: 3000 camera-attached billboards cost about a third of the
# frame rate out on the surface, 19.4 fps against 25.1 with a fifth of them.
# It is left at full here because 19.4 is what the indoor maps run at anyway,
# so the snow is not what makes the surface slow. Set it to 0.5 for 22.6 fps if
# you would rather have the speed than the weather.

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

$GPTOKEYB "PenumbraOverture" -c "$GAME_DIR/penumbra.gptk" &
GPTOKEYB_PID=$!

"$GAME_DIR/PenumbraOverture"

# pidof prints nothing when it is already gone, and kill with no argument then
# prints its usage into the log and returns an error, which looks like a fault
# in the port. Kill what was actually started.
if [ -n "$GPTOKEYB_PID" ] && kill -0 "$GPTOKEYB_PID" 2>/dev/null; then
  $ESUDO kill -9 "$GPTOKEYB_PID" 2>/dev/null
fi
unset SDL_GAMECONTROLLERCONFIG
$ESUDO systemctl restart oga_events &
printf "\033c" > /dev/tty0
