#!/usr/bin/env bash
# Escape hatch: the engine grabs the pointer, so if it stops responding the
# window cannot be closed by hand. It also ignores SIGTERM, hence SIGKILL.
#
# Processes are matched by /proc/*/exe rather than the command line, so this
# never kills the shell that runs it - and by this directory rather than a
# hardcoded name, so renaming the checkout cannot break it.
HERE=$(cd "$(dirname "$0")" && pwd)

for e in /proc/[0-9]*/exe; do
	tgt=$(readlink "$e" 2>/dev/null) || continue
	case "$tgt" in
		"$HERE"/*PenumbraOverture*)
			pid=$(basename "$(dirname "$e")")
			echo "killing $pid"
			kill -KILL "$pid" 2>/dev/null
			;;
	esac
done
