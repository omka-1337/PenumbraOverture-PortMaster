## Notes

Thanks to [Frictional Games](https://store.steampowered.com/app/22180/) for creating Penumbra: Overture, a first person survival horror with no weapon worth the name, where every door, drawer and valve is opened by physically pulling it with the mouse rather than by pressing a use key.

**Boots and plays.** Confirmed on an RG40XX running ROCKNIX on 2026-10-04. A full playthrough on the device has not been done yet, and no other firmware has been tried, so treat the other CFWs as untested rather than as working.

The game is paid, so only the engine ships here. That engine is [HPL1 Fledged](../../HPL1-Fledged), a continuation of zenmumbler's HPL1 Rehatched, which is in turn Frictional Games' own GPL release of HPL1 with the dead NVIDIA Cg shader toolkit replaced by GLSL. You supply the game's own files, about 787 MB of them.

## Contents

- [Installing](#installing)
  - [1. Install the port](#1-install-the-port)
  - [2. Copy the game across](#2-copy-the-game-across)
  - [3. Play](#3-play)
- [Graphics switches](#graphics-switches)
- [Controls](#controls)
- [Compile](#compile)

## Installing

You need: your own copy of Penumbra: Overture, a PC to copy it from, a handheld running PortMaster, and 800 MB free on the games card. Budget twenty minutes, almost all of it copying files.

### 1. Install the port

Drop `penumbra.zip` into PortMaster's `autoinstall` folder and run PortMaster, which unpacks it and clears the folder.

Over ssh it is one command instead:

```
harbourmaster install <url of the zip>
```

Either way you end up with `Penumbra Overture.sh` and a `penumbra/` folder in `ports/`. The folder holds the engine, its shaders and an OpenAL build, and waits for the game.

### 2. Copy the game across

From your game folder, copy these into `ports/penumbra/`, alongside the engine. The layout below is the Steam release, which ships the 2007 Linux build; other releases were not checked, so compare before assuming the names match:

```
billboards/   lights/      particles/    materials.cfg
config/       maps/        sounds/       resources.cfg
core/         models/      textures/
fonts/        music/
graphics/
```

Leave behind `penumbra`, `penumbra.bin` and `lib/`. Those are the 2007 Linux build and its bundled libraries, which this port replaces; the engine here is a separate binary and does not read them. `CHANGELOG.txt`, `Manual.pdf`, `README.linux`, `eng_license.rtf`, `penumbra.png` and `openurl.sh` are not used either, though they do no harm.

Do not overwrite the `rehatched/` folder that came with the port. It is not part of the retail data: it carries the shaders the engine compiles at startup, plus a handful of script and config overrides. Without it the game starts and then draws nothing, which looks like a broken port rather than a missing folder.

### 3. Play

Launch Penumbra Overture from the Ports menu. The first run writes a settings file and takes a few seconds longer than the ones after it.

Saves and settings go to `ports/penumbra/.frictionalgames/`, because the launch script points `HOME` at the port folder. They survive reinstalling the port as long as you keep that folder.

If it does not start, read `ports/penumbra/log.txt`, which the launch script captures on every run. The lines near the top name the GL driver, so `Vendor: Mesa` with `(Panfrost)` tells you it came up on ROCKNIX's mainline stack and `Vendor: ARM` tells you it came up on the vendor blob.

## Graphics switches

The engine reads a few environment variables at startup, which is the cheapest way to trade detail for frame rate without rebuilding. Set them in the launch script, before the line that runs `./PenumbraOverture`.

| Variable | Default | Effect |
|--|--|--|
| `HPL_SHADOW_BUDGET` | `2` | How many point lights get a shadow cube map. `0` leaves spot light shadows only, which is the biggest single saving. |
| `HPL_POINT_SHADOWS` | on | `0` turns point light shadows off outright. |
| `HPL_POST` | on | `0` skips the off-screen pass, losing gamma and bloom but saving a full-screen resolve. |
| `HPL_BLOOM` | from config | A number overrides the bloom amount. `0` disables bloom but keeps the pass. |
| `HPL_GAMMA` | from config | A number overrides gamma. |
| `HPL_BUMP` | on | `0` lights surfaces flat instead of through their normal maps. |
| `HPL_GLES` | auto | Forces the GLES path on or off. The aarch64 build is GLES only, so there is nothing to force here. |

`HPL_NO_LIGHTS`, `HPL_FRAME_TRACE` and `HPL_SCREENSHOT` also exist but are debugging aids, not settings worth shipping.

## Controls

| Button | Key | Action |
|--|--|--|
| Left stick | W A S D | Move |
| Right stick | Mouse | Look, and drag things while Interact is held |
| R1 | Left mouse | Interact: hold and pull to open doors, drawers and valves |
| L1 | Right mouse | Examine |
| A | Space | Jump |
| B | R | Interaction mode |
| X | F | Flashlight |
| Y | G | Glowstick |
| L2 | Left Shift | Run |
| R2 | Left Ctrl | Crouch |
| L3 | Q | Lean left |
| R3 | E | Lean right |
| Select | Tab | Inventory |
| Start | Escape | Menu |

Face button positions vary between handhelds, so A and B may sit the other way round on yours. The port remaps nothing: `gptokeyb` translates the pad into the keyboard and mouse the game already reads, and the mapping in `penumbra.gptk` names the physical buttons.

Two things are not on the pad yet. The notebook and the personal notes, `N` and `P` on a keyboard, have no button, and the D-pad sends the arrow keys, which this game never reads. The D-pad is therefore the obvious home for them.

## Compile

The engine is a separate repository, [HPL1 Fledged](../../HPL1-Fledged), and this repository holds the game sources, the packaging and the launch script. Clone them side by side.

For the device, the build runs in the PortMaster container, so register arm64 emulation once:

```
docker run --privileged --rm tonistiigi/binfmt --install arm64
./build-arm64.sh
```

That produces `build-arm64/PenumbraOverture`, a 7 MB aarch64 binary needing glibc 2.29 or newer and linking `libGLESv2`. `Dockerfile.arm64` sits on top of `monkeyx/retro_builder:arm64` and adds g++-10, because the image's gcc 9 has no `<span>`.

For a desktop build, to work on the engine itself:

```
cmake -S . -B build && cmake --build build
./play.sh
```

`port/README.md` describes the layout on the device, and `capture.sh` drives the game unattended to grab a single frame, which is how the renderer was compared against the original.
