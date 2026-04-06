#!/usr/bin/env bash
# shellcheck disable=1091,2034

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

run_swaylock(){
  clear_pass_clip
  # if pgrep 'swayidle'; then pkill --oldest 'swayidle'; fi

  logger "WAYLOCK: $(pgrep 'waylock')"
    #-fork-on-lock \
  waylock -fork-on-lock \
    -init-color 0x1e222a \
    -input-color 0x2d3343 \
    -fail-color 0xe06c75

  # if ! pgrep 'swaylock'; then
  #   command "${BASH_LIB}/sway/swaylock.sh"
  #   logger "SWAYLOCK: run command"
  # fi
}

# runp_swaylock(){
#   command "$BASH_LIB/sway/swaylock.sh" --process &
#   waitpid "$!"
#   run_swaylock
# }

lockctl() {
  case "${1-}" in
    -s|--allow-sleep|-h|--allow-hibernate)
      lidctl "$@"
      ;;
    --clear)
      clear_pass_clip
      ;;
    --lock)
      run_swaylock
      ;;
    --unlock)
      run_swaymonitors
      ;;
    --suspend)
      if check_flags ALLOW_SLEEP; then
        run_swaylock && systemctl sleep
      else
        run_swaylock
      fi
      ;;
    --hibernate)
      if check_flags ALLOW_HIBERNATE; then
        run_swaylock && systemctl hibernate
      else
        run_swaylock
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
      case "$(get_lid_state)" in
        open)
          run_swaymonitors
          ;;
        close)
          if check_flags ALLOW_SLEEP; then
            run_swaylock && systemctl sleep
          else
            run_swaylock
          fi
          ;;
      esac
    ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  lockctl "$@"
fi
