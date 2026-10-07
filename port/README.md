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
