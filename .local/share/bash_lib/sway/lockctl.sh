#!/usr/bin/env bash
# shellcheck disable=1091,2034
source /usr/local/bin/userenv
source "${BASH_LIB}/sway/pass.sh"
source "${BASH_LIB}/sway/lidctl.sh"
source "${BASH_LIB}/utils/ulaptop"

set -euo pipefail

clear_pass() {
  _pass --clear
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
  # swaymsg reload
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
    --allow-sleep|-s)
      case "${2:-''}" in
        yes) set_flags ALLOW_SLEEP 0 ;;
        no)  set_flags ALLOW_SLEEP 1 ;;
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
        yes) set_flags ALLOW_HIBERNATE 0 ;;
        no)  set_flags ALLOW_HIBERNATE 1 ;;
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
    --clear)  clear_ph ;;
    --lock)   clear_ph && run_swaylock ;;
    --unlock) run_kanshi ;;
    --suspend)
        clear_ph && run_swaylock
        if check_flags ALLOW_SLEEP; then
          systemctl sleep
        fi
      ;;
    --hibernate)
        clear_ph && run_swaylock
        if check_flags ALLOW_HIBERNATE; then
          systemctl hibernate
        fi
      ;;
    --logout)   clear_ph && swaymsg exit ;;
    --reboot)   clear_ph && systemctl reboot;;
    --shutdown) clear_ph && systemctl poweroff;;
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
            charging)
              if [ "$(run_kanshi)" == "laptop" ]; then
                clear_ph && run_swaylock
                systemctl sleep
              fi
            ;;
            discharging) 
              clear_ph && run_swaylock
              if check_flags ALLOW_SLEEP; then
                systemctl sleep
              fi
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
