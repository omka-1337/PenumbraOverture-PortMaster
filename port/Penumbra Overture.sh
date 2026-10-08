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
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR=/$directory/ports/penumbra

cd $GAMEDIR

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

$ESUDO chmod 666 /dev/uinput
chmod +x "$GAMEDIR/PenumbraOverture"

# Only OpenAL is carried along; SDL2 and GLES come from the system.
export LD_LIBRARY_PATH="$GAMEDIR/libs:$LD_LIBRARY_PATH"

# The engine keeps settings and saves under $HOME, which must be writable.
#
# This is the game folder itself, not a subfolder of it. A tidier layout was
# tried and it orphaned every existing save, because the saves are already at
# $GAMEDIR/.frictionalgames and moving $HOME moves where the game looks for
# them. Anyone who has played this port has saves in that place; leave it alone.
export HOME="$GAMEDIR"

# A touchscreen reports where a finger is, not how far it moved, so letting it
# act as a mouse plants the pointer at an absolute spot and the view stops
# turning. Devices with one are the ones that need this most.
if [ "$CFW_NAME" = "ROCKNIX" ]; then
  export SDL_TOUCH_MOUSE_EVENTS=0
  swaymsg input type:touch events disabled 2>/dev/null
fi

# The stick reports no tilt on several of these devices, only on or off, so one
# speed has to serve both landing on an inventory slot and turning round, and no
# single speed does. The base speed is set in penumbra.gptk (mouse_scale); this
# is the ramp on top of it, as <top speed>:<how fast it gets there>:<starting
# speed>. A short push moves at the base speed and a push you hold climbs to
# three times that over about a second, dropping back when you let go. Lower the
# middle number if the change of speed is itself noticeable: the pointer moves
# once per drawn frame, so a gain that climbs quickly reads as surging.
export HPL_MOUSE_ACCEL=3:2:1

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

$GPTOKEYB "PenumbraOverture" -c "$GAMEDIR/penumbra.gptk" &
GPTOKEYB_PID=$!

# Hand the window the pointer focus once it exists.
#
# On ROCKNIX the frontend is a sway client and keeps the focus when it starts
# this port. The first run after a boot happens to get it anyway; every run
# after that comes up focused on the frontend, so the compositor sends the
# pointer events there and none reach the game: SDL reports relative mouse mode
# on while nothing arrives, and the view will not turn. The engine logs that as
# "Mouse after 600 frames: 0 carried relative motion".
#
# Asking sway directly is the only thing that moves it. Harmless anywhere else:
# without swaymsg the whole block is skipped.
if command -v swaymsg >/dev/null 2>&1; then
  (
    for dir in "$XDG_RUNTIME_DIR" /var/run/0-runtime-dir /run/user/0; do
      [ -n "$dir" ] || continue
      sock=$(ls "$dir"/sway-ipc*.sock 2>/dev/null | head -1)
      [ -n "$sock" ] && break
    done
    [ -n "$sock" ] || exit 0
    export SWAYSOCK="$sock"
    # The window takes a few seconds to appear, so keep asking for a while.
    for _ in 1 2 3 4 5 6 7 8; do
      sleep 2
      swaymsg '[app_id="PenumbraOverture"] focus' >/dev/null 2>&1
    done
  ) &
fi

"$GAMEDIR/PenumbraOverture"

# pidof prints nothing when it is already gone, and kill with no argument then
# prints its usage into the log and returns an error, which looks like a fault
# in the port. Kill what was actually started.
if [ -n "$GPTOKEYB_PID" ] && kill -0 "$GPTOKEYB_PID" 2>/dev/null; then
  $ESUDO kill -9 "$GPTOKEYB_PID" 2>/dev/null
fi

unset SDL_GAMECONTROLLERCONFIG
$ESUDO systemctl restart oga_events &
printf "\033c" > /dev/tty0
