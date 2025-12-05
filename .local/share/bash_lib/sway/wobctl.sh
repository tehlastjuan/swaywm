#!/usr/bin/env bash
# shellcheck disable=1091,2034
source /usr/local/bin/userenv

WOB_CFG="$XDG_CONFIG_HOME/wob/wob.ini"
export WOB_PIPE="$XDG_RUNTIME_DIR/wob.sock"

#----- onscreen bar

init_wob() {
  [ -p "$WOB_PIPE" ] || rm -f "$WOB_PIPE"
  local wobpid
  wobpid=$(pgrep "wob")
  if [ "$wobpid" -gt 0 ]; then kill "$wobpid"; fi
  mkfifo "${XDG_RUNTIME_DIR}/wob.sock" &&
    tail -f "${XDG_RUNTIME_DIR}/wob.sock" | wob -c "$WOB_CFG"
}

show_wob() {
  [[ -p "$WOB_PIPE" ]] || { init_wob; }
  echo "${1}" > "$WOB_PIPE"
}

_prt_wobctl_info() {
  cat << EOF
usage: wobctl.sh [OPT] [ARG?]
       wobctl.sh [--init|-i]
       wobctl.sh [--show|-s] [VALUE]
EOF
}

_wobctl() {
  case "${1:-''}" in
    --init|-i) init_wob ;;
    --show|-s) show_wob "$2" ;;
    *)         _prt_wobctl_info ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _wobctl "$@"
fi
