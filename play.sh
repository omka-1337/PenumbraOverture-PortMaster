#!/usr/bin/env bash
# Launch the Linux build against the retail data symlinked into run/.
# The engine resolves its data dir from the executable's own location,
# so it has to be started from inside run/.
set -e
cd "$(dirname "$0")"

if [ build/PenumbraOverture -nt run/PenumbraOverture ]; then
	echo "-- newer build found, updating run/PenumbraOverture"
	rm -f run/PenumbraOverture            # unlink so a running instance is unaffected
	cp build/PenumbraOverture run/PenumbraOverture
fi

cd run
exec ./PenumbraOverture "$@"
