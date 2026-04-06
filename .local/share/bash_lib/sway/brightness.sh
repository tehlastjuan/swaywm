#!/usr/bin/env bash
# shellcheck disable=1091,2034

source /usr/local/bin/userenv --
source "$BASH_LIB/sway/wobctl.sh"

FACTOR=2
CURRENT_ABS=$(brightnessctl get)
MAX=$(brightnessctl max)
BRIGHTNESS_STEP=$((MAX * FACTOR / 100 < 1 ? 1 : MAX * FACTOR / 100))

current_brightness() {
  echo "$(brightnessctl get) * 100 / $(brightnessctl max)" | bc
}

# kill_brightness() {
#   kill "$(ps aux | grep 'brightness.sh --*' | awk '{print $2}')"
#   # pkill --uid "$USER" --oldest "/home/juanro/.local/share/bash_lib/sway/brightness.sh"
#   # pkill --uid "$USER" --newest "/home/juanro/.local/share/bash_lib/sway/brightness.sh"
# }

brightness() {
  case "${1-}" in
    --get)
      current_brightness
      ;;
    --down)
      # if current value <= 2% and absolute value != 1, set brightness to absolute 1
      if [ "$(current_brightness)" -le "$FACTOR" ] && [ "$CURRENT_ABS" -ge 0 ]; then
        brightnessctl --quiet set 1
      else
        brightnessctl --quiet set "${BRIGHTNESS_STEP}-"
        wobctl --show "$(current_brightness)"
      fi
    ;;
    --up)
      brightnessctl --quiet set "${BRIGHTNESS_STEP}+"
      wobctl --show "$(current_brightness)"
      ;;
    *) exit 0 ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  brightness "$@"
fi
