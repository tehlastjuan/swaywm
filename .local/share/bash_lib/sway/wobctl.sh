#!/usr/bin/env bash

source /usr/local/bin/userenv XDG_CONFIG_HOME XDG_RUNTIME_DIR

WOB_CFG="$XDG_CONFIG_HOME/wob/wob.ini"

export WOB_PIPE="$XDG_RUNTIME_DIR/wob.sock"

#----- onscreen bar

init_wob() {
  [ -p "$WOB_PIPE" ] || rm -f "$WOB_PIPE"
  wobpid=$(pgrep "wob"); local wobpid

  if [ "$wobpid" -gt 0 ]; then kill "$wobpid"; fi
  mkfifo "${XDG_RUNTIME_DIR}/wob.sock" &&
    tail -f "${XDG_RUNTIME_DIR}/wob.sock" | wob -c "$WOB_CFG"
}

show_wob() {
  [[ -p "$WOB_PIPE" ]] || { init_wob; }
  echo "${1-}" > "$WOB_PIPE"
}

_prt_wobctl_info() {
  cat << EOF
usage: wobctl.sh [OPT] [ARG?]
       wobctl.sh [-i|--init]
       wobctl.sh [-s|--show] [VALUE]
EOF
}

_wobctl() {
  case "${1-}" in
    -i|--init) init_wob ;;
    -s|--show) shift; show_wob "${1:-0}" ;;
    *)         _prt_wobctl_info ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _wobctl "$@"
fi
