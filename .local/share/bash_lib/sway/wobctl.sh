#!/usr/bin/env bash

source /usr/local/bin/userenv --

WOB_CFG="$XDG_CONFIG_HOME/wob/wob.ini"
export WOB_PIPE="$XDG_RUNTIME_DIR/wob.sock"


#----- onscreen bar

kill_wob() {
  [ -p "$WOB_PIPE" ] || rm -f "$WOB_PIPE"
  if pgrep 'wob'; then pkill --oldest 'wob'; fi
}

init_wob() {
  kill_wob

  mkfifo "${XDG_RUNTIME_DIR}/wob.sock" &&
    tail -f "${XDG_RUNTIME_DIR}/wob.sock" | wob -c "$WOB_CFG"
}

show_wob() {
  [ -p "$WOB_PIPE" ] || { init_wob; }
  echo "${1:-0}" > "$WOB_PIPE"
}

_prt_wobctl_info() {
  cat << EOF
usage: wobctl.sh [OPT] [ARG?]
       wobctl.sh [-i|--init]
       wobctl.sh [-s|--show] [VALUE]
       wobctl.sh [-k|--kill]
EOF
}

wobctl() {
  case "${1-}" in
    -h|--help)
      _prt_wobctl_info
      ;;
    -i|--init)
      init_wob
      ;;
    -k|--kill)
      kill_wob
      ;;
    -s|--show)
      shift
      show_wob "$@"
      ;;
  esac
}

if [ "${#BASH_SOURCE[@]}" -eq 1 ]; then
  wobctl "$@"
fi
