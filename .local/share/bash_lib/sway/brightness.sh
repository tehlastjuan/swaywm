#!/usr/bin/env bash
# shellcheck disable=1091,2034

source /usr/local/bin/userenv export_env BASH_LIB
source "$BASH_LIB/sway/wobctl.sh"

CURRENT_ABS=$(brightnessctl get)
MAX=$(brightnessctl max)
FACTOR=2
BRIGHTNESS_STEP=$((MAX * FACTOR / 100 < 1 ? 1 : MAX * FACTOR / 100))

current_br() {
  echo "$(brightnessctl get) * 100 / $(brightnessctl max)" | bc
}

_brightness() {
  case $1'' in
    --down)
      # if current value <= 2% and absolute value != 1, set brightness to absolute 1
      if [ "$(current_br)" -le "$FACTOR" ] && [ "$CURRENT_ABS" -ge 0 ]; then
        brightnessctl --quiet set 1
      else
        brightnessctl --quiet set "${BRIGHTNESS_STEP}-"
      fi
    ;;
    --up) brightnessctl --quiet set "${BRIGHTNESS_STEP}+" ;;
    *) ;;
  esac

  show_wob "$(current_br)"
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _brightness "$@"
fi
