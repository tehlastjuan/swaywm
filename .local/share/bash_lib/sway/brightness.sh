#!/usr/bin/env bash
# shellcheck disable=1091,2034

BASH_LIB="$XDG_DATA_HOME/bash_lib"

FACTOR=2
MAX=$(brightnessctl max)
CURRENT_ABS=$(brightnessctl get)
BRIGHTNESS_STEP=$((MAX * FACTOR / 100 < 1 ? 1 : MAX * FACTOR / 100))

function _get_current_brightness() {
  prinf '%s' "$(brightnessctl get) * 100 / $(brightnessctl max)" | bc
}

function _brightness() {
  case "${1-}" in
    --get)
      shift
      case "${1-}" in
        --json)
          # format
          # {"text": "$text", "alt": "$alt", "tooltip": "$tooltip", "class": "$class", "percentage": $_percentage }"
          local _alt _json _cur_brightness
          _cur_brightness=$(_get_current_brightness)

          if [[ "$_cur_brightness" -gt 0 && "$_cur_brightness" -lt 9 ]]; then _alt=10; fi
          if [[ "$_cur_brightness" -gt 10 && "$_cur_brightness" -lt 19 ]]; then _alt=20; fi
          if [[ "$_cur_brightness" -gt 20 && "$_cur_brightness" -le 29 ]]; then _alt=30; fi
          if [[ "$_cur_brightness" -gt 30 && "$_cur_brightness" -le 39 ]]; then _alt=40; fi
          if [[ "$_cur_brightness" -gt 40 && "$_cur_brightness" -le 49 ]]; then _alt=50; fi
          if [[ "$_cur_brightness" -gt 50 && "$_cur_brightness" -le 59 ]]; then _alt=60; fi
          if [[ "$_cur_brightness" -gt 60 && "$_cur_brightness" -le 69 ]]; then _alt=70; fi
          if [[ "$_cur_brightness" -gt 70 && "$_cur_brightness" -le 79 ]]; then _alt=80; fi
          if [[ "$_cur_brightness" -gt 80 && "$_cur_brightness" -le 89 ]]; then _alt=90; fi
          if [[ "$_cur_brightness" -gt 90 && "$_cur_brightness" -le 100 ]]; then _alt=100; fi

          _json=$(cat << EOT
{
  "text": "brightness",
  "alt": "${_cur_brightness}",
  "tooltip": "Brightness: ${_cur_brightness}%",
  "class": "brightness",
  "percentage": ${_cur_brightness}
}
EOT
)
          printf '%s' "$_json" | jq --unbuffered --compact-output
          ;;
        *)
          _get_current_brightness
          ;;
      esac
      ;;
    --down)
      # if current value <= 2% and absolute value != 1, set brightness to absolute 1
      if [ "$(_get_current_brightness)" -le "$FACTOR" ] &&
        [ "$CURRENT_ABS" -ge 0 ]; then
        brightnessctl --quiet set 1
      else
        brightnessctl --quiet set "${BRIGHTNESS_STEP}-"
      fi
    ;;
    --up)
      brightnessctl --quiet set "${BRIGHTNESS_STEP}+"
      ;;
    *) exit 0 ;;
  esac
}

if [ "${#BASH_SOURCE[@]}" -eq 1 ]; then
  _brightness "$@"
fi
