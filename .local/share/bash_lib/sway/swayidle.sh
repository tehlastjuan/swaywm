#!/usr/bin/env bash
source /usr/local/bin/userenv

set -euo pipefail

_swayidle() {
  local idle_timeout=24
  local lock_timeout=30
  local screen_timeout=420
  local sleep_timeout=900

  if pgrep swayidle; then pkill -x swayidle; fi

  swayidle -w \
    timeout "$idle_timeout" 'brightnessctl -s && brightnessctl set 30%', resume 'brightnessctl -r' \
    timeout "$lock_timeout" "$BASH_LIB/sway/swaylock.sh --daemon" \
    timeout "$screen_timeout" 'swaymsg "output * dpms off"', resume 'swaymsg "output * dpms on"' \
    timeout "$sleep_timeout" "swaymsg \"output \* dpms off\"; sleep 2; $BASH_LIB/sway/swaylock.sh --daemon" \
    before-sleep 'sleep 2' \
    after-resume 'swaymsg "output * dpms on' \
    after-resume 'brightnessctl -r'
  }

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _swayidle
fi
