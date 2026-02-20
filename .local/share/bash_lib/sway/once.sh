#!/usr/bin/env sh

. /usr/local/bin/userenv

[ -z "$3" ] && exit 1

LOCKFILE="$XDG_STATE_HOME/${3}.lock"

# Kills the process if it's already running
lsof -Fp "$LOCKFILE" | sed 's/^p//' | xargs -r kill

flock --verbose -n "$LOCKFILE" "$@"
