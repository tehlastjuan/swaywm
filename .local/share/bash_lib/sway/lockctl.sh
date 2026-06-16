#!/usr/bin/env bash
# shellcheck disable=1091,2034

# set -x

source /usr/local/bin/userenv --
source "${BASH_LIB}/utils/ulaptop"
source "${BASH_LIB}/sway/lidctl.sh"

clear_pass_clip() {
  command "${BASH_LIB}/sway/pass.sh" --clear
  if [ -f "$XDG_CACHE_HOME/cliphist/db" ]; then
    rm -f "$XDG_CACHE_HOME/cliphist/db"
  fi
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

# get_inhibit_status() {
#   ps -ef | grep -v grep | grep -m 1 -q "systemd-inhibit --what=idle"
# }

# inhibit_status() {
#   local class='' text=''
#   if get_inhibit_status; then
#     class="on"
#     text="Inhibiting idle (Mid click to clear)"
#   else
#     class="off"
#     text="Idle not inhibited"
#   fi
#   printf '{"alt":"%s","tooltip":"%s"}\n' "$class" "$text"
# }

# inhibit_min() {
#   systemd-inhibit \
#     --what=idle \
#     --who=swayidle-inhibit \
#     --why=commanded \
#     --mode=block sleep "${1:-0}" &
#   waybar-signal idle
# }

run_swaymonitors() {
  command "$BASH_LIB/sway/swaymonitors.sh" --profile --refresh
}

run_swayidle() {
  if ! pgrep 'swayidle'; then
    command "$BASH_LIB/sway/swayidle.sh"
  fi
}

run_waylock(){
  clear_pass_clip

  logger "WAYLOCK(${1-}): $(pgrep 'waylock')"
  command "${BASH_LIB}/sway/swaylock.sh"

  # if ! pgrep 'waylock'; then
  #   command "${BASH_LIB}/sway/swaylock.sh"
  # fi
}

lockctl() {
  logger "lockctl: $(printf '%s ' "$@")"
  case "${1-}" in
    -s|--allow-sleep)
      lidctl.sh "$@"
      ;;
    -h|--allow-hibernate)
      lidctl.sh "$@"
      ;;
    --clear)
      clear_pass_clip
      ;;
    --lock)
      run_waylock
      ;;
    --unlock)
      run_swaymonitors
      ;;
    --suspend)
      run_waylock "${1}"
      if check_flags ALLOW_SLEEP; then
        systemctl sleep
      fi
      ;;
    --hibernate)
      run_waylock "${1}"
      if check_flags ALLOW_HIBERNATE; then
        systemctl hibernate
      fi
      ;;
    --logout)
      clear_pass_clip && swaymsg exit
      ;;
    --reboot)
      clear_pass_clip && systemctl reboot
      ;;
    --shutdown)
      clear_pass_clip && systemctl poweroff
      ;;
    --lid)
      # logger "lockctl: $(get_lid_state)"
      # logger "lockctl: $(get_battery_state)"
      case "$(get_lid_state)" in
        open)
          run_swaymonitors
          swaymsg reload
          ;;
        close)
          case "$(get_battery_state)" in
            charging)
              run_swaymonitors
              swaymsg reload
              ;;
            discharging)
              run_waylock "${1} close"
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

if [ "${#BASH_SOURCE[@]}" -eq 1 ]; then
  lockctl "$@"
fi
