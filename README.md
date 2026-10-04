# Penumbra: Overture — PortMaster port

A port of Penumbra: Overture to ARM handhelds, built on
[HPL1 Fledged](../../HPL1-Fledged) — the engine lives in its own repository.

`PenumbraOverture/` is the game's own source, released by Frictional Games under
the GPL in 2010 and modernised in [HPL1 Rehatched](https://github.com/sysfce2/HPL1R)
by zenmumbler, whose work both this port and the engine fork continue. Thank you.
Only two files carry changes made here, `src/Init.cpp` and
`src/PlayerState_Interact.cpp`; everything else in that directory is as it came.

The game data comes from the player's own copy — textures, models, sounds,
music and compiled maps are not in this repository and will not be. What is
here under `rehatched/` is the handful of script and config overrides inherited
from HPL1 Rehatched: seven `.hps` map scripts, `English.lang`, `resources.cfg`,
one GUI sound and zenmumbler's material-checking tooling.

## Building

    cmake -S . -B build && cmake --build build

The engine is expected next to this port as `../../HPL1-Fledged`; pass
`-DHPL1_ENGINE_DIR=<path>` for a checkout elsewhere.

For the device:

    docker run --privileged --rm tonistiigi/binfmt --install arm64   # once
    ./build-arm64.sh

## Running it here

`run/` holds symlinks to the retail data plus the built binary.

    ./play.sh                      # play
    ./kill-game.sh                 # the engine ignores SIGTERM
    ./capture.sh 900 /tmp/f.ppm    # one frame, without a person driving it

Switches, all read from the environment: `HPL_GLES`, `HPL_GAMMA`, `HPL_BLOOM`,
`HPL_BUMP`, `HPL_NO_LIGHTS`, `HPL_POST`, `HPL_POINT_SHADOWS`,
`HPL_SHADOW_BUDGET`, `HPL_FRAME_TRACE`, `HPL_SCREENSHOT`.

## Packaging

See `port/README.md` for the layout on the device.

## License

GPL-3.0-or-later, inherited and unavoidable: the game sources came out under the
GPL and the licence travels with them. `LICENSE` is the GPL v3 text verbatim.
Sources under `PenumbraOverture/` carry their original 2006-2010 Frictional
Games headers, bar three of zenmumbler's own additions; the scripts and build
files here were written by Omka1337 with the help of Claude Code.

Penumbra: Overture's assets are the property of Frictional Games. Beyond the
`rehatched/` overrides described above, none are redistributed here. Buy the
game.
