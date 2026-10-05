#!/bin/bash
# PORTMASTER: penumbra.zip, Penumbra Overture.sh

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
source $controlfolder/device_info.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

PORTS_DIR="/$directory/ports"
GAME_DIR="${PORTS_DIR}/penumbra"
LOG_FILE="${GAME_DIR}/log.txt"
cd "$GAME_DIR"

exec > >(tee "$LOG_FILE") 2>&1

$ESUDO chmod 666 /dev/uinput
chmod +x "$GAME_DIR/PenumbraOverture"

# Only OpenAL is carried along; SDL2 and GLES come from the system.
export LD_LIBRARY_PATH="$GAME_DIR/libs:$LD_LIBRARY_PATH"

# The engine keeps settings and saves under $HOME, which must be writable.
export HOME="$GAME_DIR"

# A thumb stick has to both aim at a keyhole and turn you round, which one
# sensitivity cannot do. This leaves a short nudge alone and lets a held
# movement build up to triple speed over about half a second. Raise the first
# number for faster turning, the second for a shorter run-up.
export HPL_MOUSE_ACCEL=3:4

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

$GPTOKEYB "PenumbraOverture" -c "./penumbra.gptk" &
./PenumbraOverture

$ESUDO kill -9 $(pidof gptokeyb)
unset SDL_GAMECONTROLLERCONFIG
$ESUDO systemctl restart oga_events &
printf "\033c" > /dev/tty0
