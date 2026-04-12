#!/usr/bin/env bash
# shellcheck disable=1091,2034

source /usr/local/bin/userenv --
source "${BASH_LIB}/utils/ulaptop"
source "${BASH_LIB}/sway/workspaces.sh"

# set -x

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

# pos 0 0, scale 1.0, transform 90
declare -A PROFILE_DEFAULT
PROFILE_DEFAULT[VERT]="disable"
PROFILE_DEFAULT[WIDE]="disable"
PROFILE_DEFAULT[LPTP]="0 0,1.13"

declare -A PROFILE_DOCKED
PROFILE_DOCKED[VERT]="0 0,1.0,90"
PROFILE_DOCKED[WIDE]="1080 0,1.0"
PROFILE_DOCKED[LPTP]="disable"

declare -A PROFILE_MULTI
PROFILE_MULTI[VERT]="0 0,1.0,90"
PROFILE_MULTI[WIDE]="1080 0,1.0"
PROFILE_MULTI[LPTP]="3640 0,1.13"
PROFILE_MULTI[TELE]="5560 0,2.0"
PROFILE_MULTI[KAUS]="5560 0,2.0"

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
    while IFS=',' read -r key monitor_name width height res scale transform; do
      [ "$transform" = "null" ] || [ "$transform" = "normal" ] && transform=0
      CURR_OUTPUTS_CFG["$key"]="${monitor_name},${width},${height},${res},${scale},${transform}"
    done<<<"$(get_output "$output" --config)"
  done

  # for name in "${!CURR_OUTPUTS_CFG[@]}"; do
  #   echo "CURR_CFG: [$name] ${CURR_OUTPUTS_CFG[$name]}"
  # done

  while IFS='=' read -r key monitor_name; do
    ACTIVE_OUTPUTS["$key"]="$monitor_name"
  done<<<"$(get_outputs_active --key-name)"

  #TODO: add ACTIVE_OUTPUTS_CFG setup
  for output in "${!ACTIVE_OUTPUTS[@]}"; do
    while IFS=',' read -r key monitor_name width height res scale transform; do
      [ "$transform" = "null" ] || [ "$transform" = "normal" ] && transform=0
      ACTIVE_OUTPUTS_CFG["$key"]="${monitor_name},${width},${height},${res},${scale},${transform}"
    done<<<"$(get_output "$output" --config)"
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
  [ -z "$output_name" ] && output_name=$(get_outputs_focused --key)
  swaymsg focus output \'"$output_name"\'
}

#----- config

delete_config() {
  if [ -f "$MONITOR_CONF" ]; then rm "$MONITOR_CONF"; fi
  return
}

set_config() {
  local key=
  local -a output_alias=()
  for output in "${!CURR_OUTPUTS[@]}"; do
    key="$(get_output_key "${CURR_OUTPUTS[$output]}")"
    output_alias+=("set \$monitor_${key,,} \"${CURR_OUTPUTS[$output]}\"")

    local -a output_config=("output $output")

    if [ "${PROFILE[$key]}" = "disable" ]; then
      output_config+=("${PROFILE[$key]}")
    else
      local -i width height res transform
      local scale="1.0"

      while IFS=',' read -r _monitor_name _width _height _res _scale _transform; do
        [ -n "$_width" ] && width=$_width
        [ -n "$_height" ] && height=$_height
        [ -n "$_res" ] && res=$_res
        [ -n "$_scale" ] && scale=$_scale
        [ -n "$_transform" ] && transform=$_transform
      done<<<"${CURR_OUTPUTS_CFG[$output]}"

      while IFS=',' read -r _pos _scale _transform _res; do
        if [ -n "$_scale" ] && [ "$(bc -l <<< "${scale}!=${_scale}")" ]
        then scale=$_scale; fi
        if [ -n "$_transform" ] && [ "$(bc -l <<< "${transform}!=${_transform}")" ]
        then transform=$_transform; fi
        if [ -n "$_res" ] && [ "$(bc -l <<< "${res}!=${_res}")" ]
        then res=$_res; fi

        [ -n "$width" ] && [ -n "$height" ] && [ -n "$res" ] && {
          output_config+=("mode ${width}x${height}@${res::2}Hz")
        }
        [ -n "$_pos" ] && output_config+=("pos ${_pos}")
        [ -n "$scale" ] && output_config+=("scale ${scale}")
        [ -n "$transform" ] && output_config+=("transform ${transform}")
      done<<<"${PROFILE[$key]}"
    fi

    # enable output config in sway
    swaymsg "${output_config[*]}"
  done

  # store output alias to sway config (for easy keymapping)
  delete_config
  printf "%s\n" "${output_alias[@]}" > "$MONITOR_CONF"
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

if [ "${#BASH_SOURCE[@]}" -eq 1 ]; then
  swaymonitors "$@"
fi
