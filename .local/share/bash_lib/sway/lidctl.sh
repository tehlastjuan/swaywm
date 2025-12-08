#!/usr/bin/env bash

set -euo pipefail

FLAGS_FILE="/tmp/userflags"

declare -A FLAGS
FLAGS[ALLOW_SLEEP]=0
FLAGS[ALLOW_HIBERNATE]=0

write_flags() {
  tee "$FLAGS_FILE" > /dev/null << EOF
${FLAGS[ALLOW_SLEEP]}
${FLAGS[ALLOW_HIBERNATE]}
EOF
}

read_flags() {
  [ ! -f "$FLAGS_FILE" ] && write_flags
  local -a flags
  mapfile -t flags < "$FLAGS_FILE"
  FLAGS[ALLOW_SLEEP]=${flags[0]}
  FLAGS[ALLOW_HIBERNATE]=${flags[1]}
}

check_flags() {
  case "$1" in
    ALLOW_SLEEP)
      read_flags
      return "${FLAGS[ALLOW_SLEEP]}"
    ;;
    ALLOW_HIBERNATE)
      read_flags
      return "${FLAGS[ALLOW_HIBERNATE]}"
    ;;
    *) return 1 ;;
  esac
}

notify_flags() {
  case "${1:-''}" in
    ALLOW_SLEEP)
      if [ "$2" -eq 0 ]; then
        notify-send "ALLOW_SLEEP true"
      else
        notify-send "ALLOW_SLEEP false"
      fi
      ;;
    ALLOW_HIBERNATE)
      if [ "$2" -eq 0 ]; then
        notify-send "ALLOW_HIBERNATE true"
      else
        notify-send "ALLOW_HIBERNATE false"
      fi
      ;;
    *) return 1 ;;
  esac
}

set_flags() {
  [ $# -lt 2 ] && return 1 
  case "${1:-''}" in
    ALLOW_SLEEP)
      read_flags
      FLAGS[ALLOW_SLEEP]=$2
      notify_flags ALLOW_SLEEP "$2"
      write_flags
      ;;
    ALLOW_HIBERNATE)
      read_flags
      FLAGS[ALLOW_HIBERNATE]=$2
      notify_flags ALLOW_HIBERNATE "$2"
      write_flags
      ;;
    *) return 1 ;;
  esac
}

_prt_flags() {
  read_flags
  cat << EOF
ALLOW_SLEEP=${FLAGS[ALLOW_SLEEP]}
ALLOW_HIBERNATE=${FLAGS[ALLOW_HIBERNATE]}
usage: lidctl [FLAG] [yes|no]
       lidctl [--allow-sleep|-s] [yes|no]
       lidctl [--allow-hibernate|-h] [yes|no]
EOF
}

_lidctl() {
  case "${1:-''}" in
    --allow-sleep|-s)
      case "${2:-''}" in
        yes)     set_flags ALLOW_SLEEP 0 ;;
        no)      set_flags ALLOW_SLEEP 1 ;;
        toggle)
          if check_flags ALLOW_SLEEP; then
            set_flags ALLOW_SLEEP 1
          else
            set_flags ALLOW_SLEEP 0
          fi
        ;;
        *) _prt_flags ;;
      esac
    ;;
    --allow-hibernate|-h)
      case "${2:-''}" in
        yes)     set_flags ALLOW_HIBERNATE 0 ;;
        no)      set_flags ALLOW_HIBERNATE 1 ;;
        toggle)
          if check_flags ALLOW_HIBERNATE; then
            set_flags ALLOW_HIBERNATE 1
          else
            set_flags ALLOW_HIBERNATE 0
          fi
        ;;
        *) _prt_flags ;;
      esac
    ;;
    *) _prt_flags ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _lidctl "$@"
fi
