#!/usr/bin/env bash
# shellcheck disable=1091,2034
source /usr/local/bin/userenv
source "$BASH_LIB/utils/ulaptop"

set -euo pipefail

declare -A OUTPUT_NAMES=(
  [LPTP]="Lenovo Group Limited 0x403A Unknown"
  [WIDE]="LG Electronics LG ULTRAWIDE 0x000029C2"
  [VERT]="Dell Inc. DELL U2421HE 4TGZX13"
)

declare -a PROFILE_STATES=(
  "laptop"
  "docked"
  "multi"
)

get_output_state() {
  local output
  local -i outputs=0
  local -a curr_outputs

  readarray -t curr_outputs <<< "$(swaymsg -t get_outputs | jq -r '[ .[] | {make, model, serial} ] | .[] | "\(.make) \(.model) \(.serial)"')"
  [ "${#curr_outputs[@]}" -eq 0 ] && {
    pkill -x "kanshi"
    swaymsg reload
    exit 1
  }

  for output in "${curr_outputs[@]}"; do
    if [[ $(echo "${OUTPUT_NAMES[@]}" | grep -o "$output" | wc -w) -gt 0 ]]; then
      case "$output" in
        "${OUTPUT_NAMES[LPTP]}") outputs=$((outputs + 1)) ;;
        "${OUTPUT_NAMES[WIDE]}") outputs=$((outputs + 1)) ;;
        "${OUTPUT_NAMES[VERT]}") outputs=$((outputs + 1)) ;;
        *) continue ;;
      esac
    fi
  done

  if [ $outputs -eq 3 ]; then
    case "$(get_lid_state)" in
      close) echo "${PROFILE_STATES[1]}" ;; # docked
      open)  echo "${PROFILE_STATES[2]}" ;; # multi
    esac
  else echo "${PROFILE_STATES[0]}"; fi      # laptop
}

_kanshictl() {
  local curr_profile

  case "${1-''}" in
    multi|docked|laptop) curr_profile="$1" ;;
    *) curr_profile="$(get_output_state)" ;;
  esac

  if pgrep -U "$_USER" kanshi; then pkill --oldest kanshi; fi
  kanshi --config "$XDG_CONFIG_HOME/kanshi/config.$curr_profile" &
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _kanshictl "$@"
fi
