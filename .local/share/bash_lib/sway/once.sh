#!/usr/bin/env sh

[ -z "${3-}" ] && exit 1

LOCKFILE="/tmp/${3}.lock"

if [ -f "$LOCKFILE" ]; then exit 0; fi

flock --verbose -n "$LOCKFILE" "$@"

if [ -f "$LOCKFILE" ]; then rm -f "$LOCKFILE"; fi
