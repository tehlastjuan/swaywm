#!/usr/bin/env bash
# shellcheck disable=1091,2034

source /usr/local/bin/userenv --

command "${BASH_LIB}/sway/swaymonitors.sh" --delete
