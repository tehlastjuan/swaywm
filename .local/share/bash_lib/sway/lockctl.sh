#!/usr/bin/env bash
# shellcheck disable=1091,2034
source /usr/local/bin/userenv
source "${BASH_LIB}/crypt/cryptpass"
source "${BASH_LIB}/utils/ulaptop"

set -euo pipefail

FLAGS_FILE="/tmp/userflags"

declare -A FLAGS
FLAGS[ALLOW_SLEEP]=0
FLAGS[ALLOW_HIBERNATE]=0

set_flags() {
  local flag=${1:-''}
  local value=${2:-0}
  case "$flag" in
    ALLOW_SLEEP) FLAGS[ALLOW_SLEEP]=$value ;;
    ALLOW_HIBERNATE) FLAGS[ALLOW_HIBERNATE]=$value ;;
    *) return 1 ;;
  esac
}

write_flags() {
  tee "$FLAGS_FILE" > /dev/null << EOF
${FLAGS[ALLOW_SLEEP]:-0}
${FLAGS[ALLOW_HIBERNATE]:-0}
EOF
}

read_flags() {
  [ ! -f "$FLAGS_FILE" ] && return 1
  local -a flags
  mapfile -t flags < "$FLAGS_FILE"
  FLAGS[ALLOW_SLEEP]=${flags[0]:-0}
  FLAGS[ALLOW_HIBERNATE]=${flags[1]:-0}
}

check_flags() {
  local flag=${1-''}
  case "$flag" in
    ALLOW_SLEEP) return "${FLAGS[ALLOW_SLEEP]}" ;;
    ALLOW_HIBERNATE) return "${FLAGS[ALLOW_HIBERNATE]}" ;;
    *) return 1 ;;
  esac
}

prt_flags() {
  read_flags
  echo "ALLOW_SLEEP     ${FLAGS[ALLOW_SLEEP]}"
  echo "ALLOW_HIBERNATE ${FLAGS[ALLOW_HIBERNATE]}"
}

_test_flags() {
  read_flags 
  prt_flags
  if check_flags ALLOW_SLEEP; then
    set_flags ALLOW_SLEEP 1
  else set_flags ALLOW_SLEEP 0; fi
  if check_flags ALLOW_HIBERNATE; then
    set_flags ALLOW_HIBERNATE 1
  else set_flags ALLOW_HIBERNATE 0; fi
  write_flags
  prt_flags
}

clear_pass() {
  pass_crypt --clear
}

clear_cliphist() {
  if [ -f "$XDG_CACHE_HOME/cliphist/db" ]; then
    rm -f "$XDG_CACHE_HOME/cliphist/db"
  fi
}

clear_ph() {
  clear_pass && clear_cliphist
}

start_windscribe() {
  if [[ $(windscribe-cli status | grep -o 'Disconnected' | wc -l) -eq 1 ]]; then
    windscribe-cli connect
  fi
}

stop_windscribe() {
  if [[ $(windscribe-cli status | grep -o 'Connected' | wc -l) -eq 1 ]]; then
    windscribe-cli disconnect
  fi
}

run_kanshi() {
  command "$BASH_LIB/sway/kanshictl.sh"
  swaymsg reload
}

run_swaylock(){
  command "${BASH_LIB}/sway/swaylock.sh" --daemon
}

runp_swaylock(){
  command "$BASH_LIB/sway/swaylock.sh" --process &
  waitpid "$!"
  run_kanshi
}

_lockctl() {
  case "${1:-''}" in
    --test)     _test_flags ;;
    --clear)     clear_ph ;;
    --lock)      clear_ph && run_swaylock ;;
    --unlock)    run_kanshi ;;
    --suspend)   
      clear_ph && run_swaylock &&
        if check_flags ALLOW_SLEEP; then systemctl sleep; fi
      ;;
    --hibernate) clear_ph && run_swaylock &&
        if check_flags ALLOW_HIBERNATE; then systemctl hibernate; fi
      ;;
    --logout)    clear_ph && swaymsg exit ;;
    --reboot)    clear_ph && systemctl reboot;;
    --shutdown)  clear_ph && systemctl poweroff;;
    *)
      case "$(get_lid_state)" in
        open)
          case "$(get_battery_state)" in
            charging)    run_kanshi ;;
            discharging) run_kanshi ;;
          esac
        ;;
        close)
          case "$(get_battery_state)" in
            charging)    run_kanshi ;;
            discharging) 
              clear_ph && run_swaylock && systemctl sleep
              ;;
          esac
        ;;
      esac
    ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _lockctl "$@"
fi
