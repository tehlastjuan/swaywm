#!/usr/bin/env bash
# shellcheck disable=1091,2034

source /usr/local/bin/userenv
source "${BASH_LIB}/sway/pass.sh"
source "${BASH_LIB}/sway/lidctl.sh"
source "${BASH_LIB}/utils/ulaptop"

# set -euo pipefail

clear_pass() {
  pass --clear
}

clear_cliphist() {
  if [ -f "$XDG_CACHE_HOME/cliphist/db" ]; then
    rm -f "$XDG_CACHE_HOME/cliphist/db"
  fi
}

clear_pass_clip() {
  clear_pass && clear_cliphist
}

# start_windscribe() {
#   if [[ $(windscribe-cli status | grep -o 'Disconnected' | wc -l) -eq 1 ]]; then
#     windscribe-cli connect
#   fi
# }

# stop_windscribe() {
#   if [[ $(windscribe-cli status | grep -o 'Connected' | wc -l) -eq 1 ]]; then
#     windscribe-cli disconnect
#   fi
# }

run_swaymonitors() {
  "$BASH_LIB/sway/swaymonitors.sh" --profile --refresh
}

run_swaylock(){
  clear_pass && clear_cliphist && "${BASH_LIB}/sway/swaylock.sh" --daemon
}

# runp_swaylock(){
#   command "$BASH_LIB/sway/swaylock.sh" --process &
#   waitpid "$!"
#   run_swaylock
# }

_lockctl() {
  case "${1-}" in
    -s|--allow-sleep)     _lidctl "$@" ;;
    -h|--allow-hibernate) _lidctl "$@" ;;
    --clear)  clear_pass_clip ;;
    --lock)   run_swaylock ;;
    --unlock) run_swaymonitors ;;
    --suspend)
        run_swaylock
        if check_flags ALLOW_SLEEP; then
          systemctl sleep
        fi
      ;;
    --hibernate)
        run_swaylock
        if check_flags ALLOW_HIBERNATE; then
          systemctl hibernate
        fi
      ;;
    --logout)   clear_pass_clip; swaymsg exit ;;
    --reboot)   clear_pass_clip; systemctl reboot;;
    --shutdown) clear_pass_clip; systemctl poweroff;;
    *)
      case "$(get_lid_state)" in
        open) run_swaymonitors && swaymsg reload ;;
        close)
          #run_swaymonitors
          case "$(get_battery_state)" in
            discharging)
              run_swaylock && if check_flags ALLOW_SLEEP; then systemctl sleep
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
