#!/usr/bin/env bash
# shellcheck disable=1091,2034

source /usr/local/bin/userenv export_env BASH_LIB DOT_FILES
source "${BASH_LIB}/utils/ulaptop"
source "${BASH_LIB}/sway/workspaces.sh"

# set -euo pipefail

declare MONITOR_CONF="$DOT_FILES/sway/.config/sway/outputs/outputs.conf"

declare -A OUTPUTS_KEY_MODEL=(
  [LPTP]="Lenovo Group Limited 0x403A Unknown"
  [WIDE]="LG Electronics LG ULTRAWIDE 0x000029C2"
  [VERT]="Dell Inc. DELL U2421HE 4TGZX13"
  [KAUS]="Philips Consumer Electronics Company 55BDL3511Q 0x01010101"
)

declare -i CURR_WORKSPACE
declare -A CURR_OUTPUTS
declare -A CURR_OUTPUTS_CFG
declare -A ACTIVE_OUTPUTS
# declare -A ACTIVE_OUTPUTS_CFG

declare -A PROFILE_DEFAULT
PROFILE_DEFAULT[VERT]="disable"
PROFILE_DEFAULT[WIDE]="disable"
PROFILE_DEFAULT[LPTP]="pos 0 0,scale 1.13"

declare -A PROFILE_DOCKED
PROFILE_DOCKED[VERT]="pos 0 0,scale 1,transform 90"
PROFILE_DOCKED[WIDE]="pos 1080 0,scale 1"
PROFILE_DOCKED[LPTP]="disable"

declare -A PROFILE_MULTI
PROFILE_MULTI[VERT]="pos 0 0,scale 1,transform 90"
PROFILE_MULTI[WIDE]="pos 1080 0,scale 1"
PROFILE_MULTI[LPTP]="pos 3640 0,scale 1.13"
PROFILE_MULTI[ANY]="pos 5560 0"

declare -n PROFILE

init() {
  CURR_WORKSPACE=$(get_focused_ws)
  export CURR_WORKSPACE

  while IFS='=' read -r name monitor_name; do
    CURR_OUTPUTS["$name"]="$monitor_name"
  done<<<"$(get_outputs_name_model)"

  # for name in "${!CURR_OUTPUTS[@]}"; do
  #   echo "[$name] ${CURR_OUTPUTS[$name]}"
  # done

  for output in "${!CURR_OUTPUTS[@]}"; do
    while IFS=',' read -r name monitor_name width height res; do
      CURR_OUTPUTS_CFG["$name"]="${monitor_name},${width}x${height}@${res::2}Hz"
    done<<<"$(get_output_config "$output")"
  done

  # for name in "${!CURR_OUTPUTS_CFG[@]}"; do
  #   echo "[$name] ${CURR_OUTPUTS_CFG[$name]}"
  # done

  while IFS='=' read -r name monitor_name; do
    ACTIVE_OUTPUTS["$name"]="$monitor_name"
  done<<<"$(get_active_outputs)"

  # for name in "${!ACTIVE_OUTPUTS[@]}"; do
  #   echo "[$name] ${ACTIVE_OUTPUTS[$name]}"
  # done

  # for output in "${!ACTIVE_OUTPUTS[@]}"; do
  #   while IFS=',' read -r name monitor_name width height res; do
  #     ACTIVE_OUTPUTS_CFG["$name"]="${monitor_name},${width}x${height}@${res::2}Hz"
  #   done<<<"$(get_output_config "$output")"
  # done

  # for name in "${!ACTIVE_OUTPUTS_CFG[@]}"; do
  #   echo "[$name] ${ACTIVE_OUTPUTS_CFG[$name]}"
  # done
}

get_output_name() {
  for name in "${!CURR_OUTPUTS[@]}"; do
    if [[ ${CURR_OUTPUTS[$name]} == "${1-}" ]]
    then echo "$name" && break; fi
  done
}

get_output_key() {
  for key in "${!OUTPUTS_KEY_MODEL[@]}"; do
    if [[ ${OUTPUTS_KEY_MODEL[$key]} == "${1-}" ]]
    then echo "$key" && break; fi
  done
}

is_output_name() {
  if [ ${CURR_OUTPUTS["${1-}"]+_} ]; then return; fi
  false
}

is_output_key() {
  if [ ${OUTPUTS_KEY_MODEL["${1-}"]+_} ]; then return; fi
  false
}

get_output_name_from_key() {
  if is_output_key "${1-}"; then
    get_output_name "${OUTPUTS_KEY_MODEL[$1]}"
  fi
}

get_output_key_from_name() {
  if is_output_name "${1-}"; then
    get_output_key "${CURR_OUTPUTS[${1}]}"
  fi
}

is_output_name_active() {
  if is_output_name "${1-}"; then
    [ ${ACTIVE_OUTPUTS["${1-}"]+_} ] && return
  fi
  false
}

is_output_key_active() {
  if is_output_key "${1-}"; then
    is_output_name_active "$(get_output_name_from_key "${1-}")" && return
  fi
  false
}

get_active_output_name_from_key() {
  if is_output_key_active "${1-}"; then
    get_output_name_from_key "${1-}"
  fi
}

get_active_output_key_from_name() {
  if is_output_name_active "${1-}"; then
    get_output_key_from_name "${1}"
  fi
}

enable_output() {
  local output_name
  output_name="$(get_output_name_from_key "${1-}")"
  # notify-send "EN: '$output_name' '$1'"
  [ -n "$output_name" ] &&
    swaymsg output \'"$output_name"\' enable
}

disable_output() {
  local output_name
  output_name="$(get_output_name_from_key "${1-}")"
  # notify-send "DIS: '$output_name' '$1'"
  [ -n "$output_name" ] &&
    swaymsg output \'"$output_name"\' disable 
}

set_focus() {
  local output_name
  output_name="$(get_active_output_name_from_key "${1-}")"
  [ -z "$output_name" ] && output_name=$(get_active_output)
  swaymsg focus output \'"$output_name"\'
}

#----- config

set_config() {
  local key
  local -a conf=()
  for output in "${!CURR_OUTPUTS[@]}"; do
    key="$(get_output_key "${CURR_OUTPUTS[$output]}")"
    conf+=("set \$monitor_${key,,} \"${CURR_OUTPUTS[$output]}\"")

    local -a tmp_conf=("output $output")
    if [ "${PROFILE[$key]}" == "disable" ]; then
      tmp_conf+=("${PROFILE[$key]}")
    else
      local _pos _extras _mode
      while IFS=',' read -r pos transform scale; do
      _pos="${pos}"
      _transform="${transform}"
      _scale="${scale}"
      done<<<"${PROFILE[$key]}"
      while IFS=',' read -r _ mode; do
        echo "$mode"
      _mode="${mode}"
      done<<<"${CURR_OUTPUTS_CFG[$output]}"

      tmp_conf+=("mode ${_mode}")
      tmp_conf+=("${_pos}")
      tmp_conf+=("${_transform}")
      tmp_conf+=("${_scale}")
    fi

    #ACTIVE_OUTPUTS_CFG["$output"]="${tmp_conf[*]}"
    swaymsg "${tmp_conf[*]}"
    conf+=("${tmp_conf[*]}")
  done

  printf "%s\n" "${conf[@]}" > "$MONITOR_CONF"
}

get_output_profile() {
  local profile="laptop"
  if [ ${#CURR_OUTPUTS[@]} -ge 2 ]; then
    case "$(get_lid_state)" in
      open)  profile="multi" ;;
      close) profile="docked" ;;
    esac
  fi
  echo "$profile"
}

set_monitor_profile() {
  case "${1-}" in
    multi)
      PROFILE=PROFILE_MULTI
      set_config
      shift; case "${1-}" in
        --refresh)
          enable_output "VERT"
          enable_output "WIDE"
          enable_output "LPTP"
          ;;
      esac
      swaymsg workspace 9, move workspace to \'"${OUTPUTS_KEY_MODEL[VERT]}"\'
      swaymsg workspace 1, move workspace to \'"${OUTPUTS_KEY_MODEL[WIDE]}"\'
      swaymsg workspace "$CURR_WORKSPACE"
      ;;
    docked)
      PROFILE=PROFILE_DOCKED
      set_config
      shift; case "${1-}" in
        --refresh)
          enable_output "VERT"
          enable_output "WIDE"
          disable_output "LPTP"
          ;;
      esac
      swaymsg workspace 9, move workspace to \'"${OUTPUTS_KEY_MODEL[VERT]}"\'
      swaymsg workspace 1, move workspace to \'"${OUTPUTS_KEY_MODEL[WIDE]}"\'
      swaymsg workspace "$CURR_WORKSPACE"
      ;;
    laptop)
      PROFILE=PROFILE_DEFAULT
      set_config
      shift; case "${1-}" in
        --refresh)
          disable_output "VERT"
          disable_output "WIDE"
          enable_output "LPTP"
          ;;
      esac
      swaymsg workspace "$CURR_WORKSPACE"
      ;;
    *) set_monitor_profile "$(get_output_profile)" --refresh ;;
  esac
}

prt_info() {
  cat << EOT
usage: swaymonitors [ARGS]
       swaymonitors [-f|--focus]                          := set focused output 
       swaymonitors [-o|--outputs]                        := get outputs in JSON format
       swaymonitors [-p|--profile] [multi|docked|laptop]  := set sway's output config
EOT
}

_swaymonitors() {
  init
  case "${1-}" in
    -f|--focus)   shift; set_focus "$@" ;;
    -o|--outputs) get_outputs ;;
    -p|--profile) shift; set_monitor_profile "$@" ;;
    -t|--test)    shift; get_output_config "$@" ;;
    #-t|--test) shift; get_output_profile; set_config "$@" ;;
    *) prt_info ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _swaymonitors "$@"
fi
