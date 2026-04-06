#!/usr/bin/env bash
# shellcheck disable=1091,2034

source /usr/local/bin/userenv --
source "${BASH_LIB}/utils/ulaptop"
source "${BASH_LIB}/sway/workspaces.sh"

set -x

declare MONITOR_CONF="$DOT_FILES/sway/.config/sway/outputs/outputs.conf"

declare -A OUTPUTS_KEY_MODEL
OUTPUTS_KEY_MODEL[LPTP]="Lenovo Group Limited 0x403A Unknown"
OUTPUTS_KEY_MODEL[WIDE]="LG Electronics LG ULTRAWIDE 0x000029C2"
OUTPUTS_KEY_MODEL[VERT]="Dell Inc. DELL U2421HE 4TGZX13"
OUTPUTS_KEY_MODEL[TELE]="Samsung Electric Company SAMSUNG 0x01000E00"
OUTPUTS_KEY_MODEL[KAUS]="Philips Consumer Electronics Company 55BDL3511Q 0x01010101"

declare -i CURR_WORKSPACE
declare -A CURR_OUTPUTS
declare -A CURR_OUTPUTS_CFG
declare -A ACTIVE_OUTPUTS
declare -A ACTIVE_OUTPUTS_CFG

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
PROFILE_MULTI[TELE]="pos 5560 0,scale 2"
PROFILE_MULTI[KAUS]="pos 5560 0,scale 2"

declare -n PROFILE

init() {
  CURR_WORKSPACE=$(get_workspace_focused)
  export CURR_WORKSPACE

  while IFS='=' read -r key monitor_name; do
    CURR_OUTPUTS["$key"]="$monitor_name"
  done<<<"$(get_outputs --key-name)"

  # for key in "${!CURR_OUTPUTS[@]}"; do
  #   echo "CURR_OUT: [$key] ${CURR_OUTPUTS[$key]}"
  # done

  for output in "${!CURR_OUTPUTS[@]}"; do
    while IFS=',' read -r name monitor_name width height res scale; do
      CURR_OUTPUTS_CFG["$name"]="${monitor_name},${width}x${height}@${res::2}Hz,${scale}"
    done<<<"$(get_output_config "$output")"
  done

  # for name in "${!CURR_OUTPUTS_CFG[@]}"; do
  #   echo "CURR_CFG: [$name] ${CURR_OUTPUTS_CFG[$name]}"
  # done

  while IFS='=' read -r key monitor_name; do
    ACTIVE_OUTPUTS["$key"]="$monitor_name"
  done<<<"$(get_outputs_active --key-name)"

  #TODO: add ACTIVE_OUTPUTS_CFG setup
  for output in "${!ACTIVE_OUTPUTS[@]}"; do
    while IFS=',' read -r key monitor_name width height res scale; do
      ACTIVE_OUTPUTS_CFG["$key"]="${monitor_name},${width}x${height}@${res::2}Hz,${scale}"
    done<<<"$(get_output_config "$output")"
  done

  # for key in "${!ACTIVE_OUTPUTS_CFG[@]}"; do
  #   echo "ACTV_CFG: [$key] ${ACTIVE_OUTPUTS_CFG[$key]}"
  # done
}

get_output_name() {
  for key in "${!CURR_OUTPUTS[@]}"; do
    if [ "${CURR_OUTPUTS[$key]}" = "${1-}" ]
    then echo "$key" && break; fi
  done
}

get_output_key() {
  for key in "${!OUTPUTS_KEY_MODEL[@]}"; do
    if [ "${OUTPUTS_KEY_MODEL[$key]}" = "${1-}" ]
    then echo "$key" && break; fi
  done
}

is_output_name() {
  if [ -n "${1-}" ] && [ "${CURR_OUTPUTS["${1-}"]+_}" ]; then return; fi
  false
}

is_output_key() {
  if [ -n "${1-}" ] && [ "${OUTPUTS_KEY_MODEL["${1-}"]+_}" ]; then return; fi
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
  echo "$1"
  if is_output_key_active "${1-}"; then
    get_output_name_from_key "$1"
  fi
}

get_active_output_key_from_name() {
  if is_output_name_active "${1-}"; then
    get_output_key_from_name "$1"
  fi
}

enable_output() {
  local output_name
  output_name="$(get_output_name_from_key "${1-}")"
  [ -n "$output_name" ] &&
    swaymsg output \'"$output_name"\' enable
}

disable_output() {
  local output_name
  output_name="$(get_output_name_from_key "${1-}")"
  [ -n "$output_name" ] &&
    swaymsg output \'"$output_name"\' disable
}

set_focus() {
  local output_name=
  output_name="$(get_active_output_name_from_key "${1-}")"
  #printf -v output_name '%s' "$(get_active_output_name_from_key "${1-}")"
  #echo "set_focus_pre: $output_name"
  [ -z "$output_name" ] && output_name=$(get_outputs_focused --key)
  swaymsg focus output \'"$output_name"\'
}

#----- config

delete_config() {
  [ -f "$MONITOR_CONF" ] && rm "$MONITOR_CONF"
}

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
      while IFS=',' read -r _ mode scale; do
        [ -n "$mode" ] && tmp_conf+=("mode ${mode}")
        [ -n "$scale" ] && tmp_conf+=("scale ${scale}")
      done<<<"${CURR_OUTPUTS_CFG[$output]}"
      while IFS=',' read -r pos scale transform; do
        [ -n "${pos}" ] && tmp_conf+=("${pos}")
        #[ -n "${scale}" ] && tmp_conf+=("${scale}")
        [ -n "${transform}" ] && tmp_conf+=("${transform}")
      done<<<"${PROFILE[$key]}"
    fi

    #ACTIVE_OUTPUTS_CFG["$output"]="${tmp_conf[*]}"
    conf+=("${tmp_conf[*]}")
    swaymsg "${tmp_conf[*]}" # enable
  done

  delete_config
  #printf "%s\n" "${conf[@]}" > "$MONITOR_CONF"
}

get_output_profile() {
  local profile="multi"
  case "${#CURR_OUTPUTS[@]}" in
    1) profile="laptop" ;;
    3)
      case "$(get_lid_state)" in
        close) profile="docked" ;;
      esac
      ;;
  esac
  printf '%s' "$profile"
}

set_monitor_profile() {
  case "${1-}" in
    laptop)
      PROFILE=PROFILE_DEFAULT
      set_config
      shift
      case "${1-}" in
        --refresh)
          enable_output "LPTP"
        ;;
      esac
      swaymsg workspace "$CURR_WORKSPACE"
      ;;
    docked)
      PROFILE=PROFILE_DOCKED
      set_config
      shift
      case "${1-}" in
        --refresh)
          for key in "${!CURR_OUTPUTS[@]}"; do
            enable_output "$key"
          done
          disable_output "LPTP"
          ;;
      esac
      swaymsg workspace 9, move workspace to \'"${OUTPUTS_KEY_MODEL[VERT]}"\'
      swaymsg workspace 1, move workspace to \'"${OUTPUTS_KEY_MODEL[WIDE]}"\'
      swaymsg workspace "$CURR_WORKSPACE"
      ;;
    multi)
      PROFILE=PROFILE_MULTI
      set_config
      shift
      case "${1-}" in
        --refresh)
          for key in "${!CURR_OUTPUTS[@]}"; do
            enable_output "$key"
          done
          ;;
      esac
      swaymsg workspace 9, move workspace to \'"${OUTPUTS_KEY_MODEL[VERT]}"\'
      swaymsg workspace 1, move workspace to \'"${OUTPUTS_KEY_MODEL[WIDE]}"\'
      swaymsg workspace "$CURR_WORKSPACE"
      ;;
    *) set_monitor_profile "$(get_output_profile)" --refresh ;;
  esac
}

prt_info() {
  cat << EOT
usage: swaymonitors [ARGS]
       swaymonitors [-f|--focus]                          := set focused output
       swaymonitors [-d|--delete]                         := delete config file
       swaymonitors [-o|--outputs]                        := get outputs in JSON format
       swaymonitors [-p|--profile] [multi|docked|laptop]  := set sway's output config
       swaymonitors [-s|--scale] [multi|docked|laptop]    := scale current monitor
EOT
}

swaymonitors() {
  init
  case "${1-}" in
    -f|--focus)
      shift
      set_focus "$@"
      ;;
    -d|--delete)
      delete_config
      ;;
    -h|--help)
      prt_info
      ;;
    -o|--outputs)
      get_outputs --key-name
      ;;
    -p|--profile)
      shift
      set_monitor_profile "$@"
      ;;
    -s|--scale)
      shift
      set_output_scale "$(get_outputs_focused --key)" "$@"
      ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  swaymonitors "$@"
fi
