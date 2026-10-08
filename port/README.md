# PortMaster package

Layout on the device:

    ports/Penumbra Overture.sh      <- this directory's .sh
    ports/penumbra/
        PenumbraOverture            <- build-arm64/PenumbraOverture
        penumbra.gptk               <- this directory's .gptk
        rehatched/                  <- from the repository root
        cover.png LICENSE NOTICE    <- from the repository root
        libs/libopenal.so.1         <- build-arm64/libs/; SDL2 and GLES come from the system
        billboards/ config/ core/ fonts/ graphics/ lights/ maps/ models/
        music/ particles/ sounds/ textures/ materials.cfg resources.cfg
                                    <- from the player's own copy of the game

The engine resolves its data directory from /proc/self/exe, so everything sits
next to the binary. The launch script points HOME at the port directory, since
settings and saves go to $HOME/.frictionalgames.

Build the binary with ./build-arm64.sh (needs arm64 emulation registered:
docker run --privileged --rm tonistiigi/binfmt --install arm64), then OpenAL
with ./build-openal-arm64.sh. ./package.sh puts all of it into
build-arm64/penumbra.zip, which is what a release ships.

## The pad mapping

`penumbra.gptk` carries no comments, because PortMaster does not allow them in
a mapping file, so the reasoning lives here.

The right stick is the mouse and R1 is its left button. That is not a choice:
this game is played by physically pulling doors, drawers and valves, so a
pointer and a hold-and-drag button have to be usable at the same time. A device
with only a left stick cannot play it.

The D-pad used to send the arrow keys, which the game never reads, so four
buttons did nothing. Left and right now step through the quick slots that hold
something, up uses the one you stepped to, and down opens the notebook, which
had no button at all. Stepping never uses an item by itself, which matters when
a slot holds the only one you have.

`mouse_scale` divides, so a bigger number gives a slower pointer. 6144 is what
the DOOM 3 port uses, which drives the view from the right stick the same way;
gptokeyb's own default of 512 is twelve times faster and unusable for aiming at
an inventory slot. The engine scales this with the panel height, so the same
number behaves the same way on a 480p handheld and on a 1080p one.

`deadzone` is set explicitly rather than left at gptokeyb's own value, which a
tester found large enough to make small, smooth movements of the right stick
impossible: the view would not start turning until the stick was already well
over. Lower it further if the view creeps while the stick is at rest, raise it
if it will not hold still.

`HPL_LOOK_SCALE` in the launch script multiplies the speed of the view only.
The cursor in the menus and the inventory keeps the speed it had, because one
setting cannot be right for both turning round and landing on an inventory
slot.

