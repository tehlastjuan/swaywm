#!/usr/bin/env bash

set -euo pipefail


#----- outputs

__get_outputs() {
  swaymsg -t get_outputs | jq -r "[ .[] | \
    { name, make, model, serial,
      active, scale, current_workspace, focused,
      default_mode: (.modes[0] | \"\(.width),\(.height),\(.refresh)\"), current_mode, rect } ]"
}

get_outputs() {
  case "${1-}" in
    --raw)
      __get_outputs
      ;;
    --key)
      __get_outputs | jq -r ".[] | .name"
      ;;
    --key-name)
      __get_outputs | jq -r ".[] | \
        { name, monitor_name: \"\(.make) \(.model) \(.serial)\" } | \
          \"\(.name)=\(.monitor_name)\""
      ;;
    --name)
      __get_outputs | jq -r ".[] | \
        { monitor_name: \"\(.make) \(.model) \(.serial)\" } | \
          \"\(.monitor_name)\""
      ;;
    *) get_outputs --key ;;
  esac
}

get_outputs_focused() {
  case "${1-}" in
    --raw)
      __get_outputs | jq -r ".[] | select(.focused==true)"
      ;;
    --key)
      __get_outputs | jq -r ".[] | select(.focused==true) | .name"
      ;;
    --key-name)
      __get_outputs | jq -r ".[] | select(.focused==true) | \
        { name, monitor_name: \"\(.make) \(.model) \(.serial)\" } | \
          \"\(.name)=\(.monitor_name)\""
      ;;
    --name)
      __get_outputs | jq -r ".[] | select(.focused==true) | \
        { monitor_name: \"\(.make) \(.model) \(.serial)\" } | \
          \"\(.monitor_name)\""
      ;;
    *) get_outputs_focused --key ;;
  esac
}

get_outputs_active() {
  case "${1-}" in
    --raw)
      __get_outputs | jq -r ".[] | select(.active==true)"
      ;;
    --key)
      __get_outputs | jq -r ".[] | select(.active==true) | .name"
      ;;
    --key-name)
      __get_outputs | jq -r ".[] | select(.active == true) | \
        { active, name, monitor_name: \"\(.make) \(.model) \(.serial)\" } | \
          \"\(.name)=\(.monitor_name)\""
      ;;
    --name)
      __get_outputs | jq -r ".[] | select(.active==true) | \
        { monitor_name: \"\(.make) \(.model) \(.serial)\" } | \
          \"\(.monitor_name)\""
      ;;
    *) get_outputs_active --key ;;
  esac
}

get_output_from_workspace() {
  case "${1-}" in
    --raw)
      __get_outputs | jq -r ".[] | select(.current_workspace==\"${1-}\")"
      ;;
    --key)
      __get_outputs | jq -r ".[] | select(.current_workspace==\"${1-}\") | .name"
      ;;
    --key-name)
      __get_outputs | jq -r ".[] | select(.current_workspace==\"${1-}\") | \
        { active, name, monitor_name: \"\(.make) \(.model) \(.serial)\" } | \
          \"\(.name)=\(.monitor_name)\""
      ;;
    --name)
      __get_outputs | jq -r ".[] | select(.current_workspace==\"${1-}\") | \
        { monitor_name: \"\(.make) \(.model) \(.serial)\" } | \
          \"\(.monitor_name)\""
      ;;
    *) get_outputs_active --key ;;
  esac
}

get_output_config() {
  case "${1-}" in
    --raw)
      shift
      __get_outputs | jq -r ". [] | select(.name == \"${1-}\" //empty)"
      ;;
    *)
      __get_outputs | jq -r ". [] | select(.name == \"${1-}\" //empty) | \
        { name, monitor_name: \"\(.make) \(.model) \(.serial)\", default_mode, scale } | \
          \"\(.name),\(.monitor_name),\(.default_mode),\(.scale)\""
      ;;
  esac
}

set_output_focused() {
  if [ "$(get_outputs | grep -Ewom1 "${1-}" | wc -l)" -gt 0 ]; then
    swaymsg focus output \'"${1-}"\'
  fi
}

set_output_scale() {
  [ -z "${1-}" ] && return 1

  local value=0.1
  local curr_scale next_scale
  curr_scale=$(get_output_config "${1-}" | cut -d ',' -f 6)

  case "${2-}" in
    down) next_scale=$(echo "$curr_scale - $value" | bc) ;;
    up)   next_scale=$(echo "$curr_scale + $value" | bc) ;;
    *)    next_scale=1 ;;
  esac

  swaymsg output "${1}" scale "$next_scale"
}


#----- workspaces

__get_ws_apps() {
  swaymsg -t get_workspaces | jq -r ". [] |
    { name, output, representation: (
      ( select(.representation!=null) |
        [.representation] |
        map(
          scan(\"T\\\[[^\\\]]*\\\]\") |
            sub(\"^T\\\[\";\"\") |
            sub(\"\\\]$\";\"\") |
            split(\" \")
          )
        )
      )
    }
  "
}

is_in_workspace() {
  local ws=
  ws=$(__get_ws_apps | jq -r ". |
    select(limit(1; .representation[][] |
    match(\"^${1-}$\"; \"x\"))) | .name" |
    sed -Ez 's/\"//g;s/\n$//g;s/\r$//g;s/\n/,/g;s/\r/,/g')
  if [ -n "${ws}" ]; then return; else false; fi
}

get_workspaces() {
  case "${1-}" in
    --raw) __get_ws_apps ;;
    *)
      local ws=

      # match app_name -> ws
      if is_in_workspace "${1-}"; then
        ws=$(__get_ws_apps | jq -r ". |
          select(limit(1; .representation[][] |
          match(\"^${1-}$\"; \"n\"))) | .name" | sed -Er 's/\"//g;')
        if [ -n "$ws" ]; then
          readarray -t _ws<<<"$ws"
          [ "${#_ws[@]}" -gt 0 ] && { printf "%s\n" "${_ws[0]}" && return; }
        fi

      # match output_key -> ws
      elif [ "$(get_outputs | grep -Ewo "^${1-}$" | wc -l)" -gt 0 ]; then
        ws=$(__get_ws_apps | jq -r ". |
          select(limit(1; .output==\"${1-}\")) | .name" |
          sed -Ez 's/\"//g;s/\n$//g;s/\r$//g;s/\n/,/g;s/\r/,/g')
        if [ -n "$ws" ]; then
          readarray -t _ws<<<"$ws"
          [ "${#_ws[@]}" -gt 0 ] && { printf "%s\n" "${_ws[0]}" && return; }
        fi
      else
        echo 0 && false
      fi
      ;;
  esac
}

get_workspace_apps() {
  __get_ws_apps
}

get_workspace_focused() {
  swaymsg -t get_workspaces | jq '.[] | select(.focused==true) | .num'
}

set_workspace_focused() {
  local -i ws=
  ws=$(get_workspaces "${1-}")

  if [ "$ws" -gt 0 ]; then
    local outputs
    outputs=$(get_output_from_workspace "$ws")
    readarray -t _outputs<<<"$outputs"
    [ "${#_outputs[@]}" -gt 0 ] && {
      echo "WS: $ws, OUTS: ${_outputs[0]}"
      swaymsg focus output \'"${_outputs[0]}"\'
    }
  fi
}


#----- main

prt_help() {
  cat << EOT
usage:  worskpaces.sh [FLAGS] [ARGS]
        *args:
        [--raw] := JSON
        [--key] := '.name'
        [--name] := '.make .model .serial'
        [--key-name] := 'name={make model serial}'

        worskpaces.sh --get-active [*]           := return active outputs
        worskpaces.sh --get-config [--raw]       := return output config: {name, monitor_name, default_mode, scale}
        worskpaces.sh --get-focused [*]          := return focused outputs
        worskpaces.sh --get-from-ws [INT]        := return output having \$workspace_number
        worskpaces.sh --get-outputs [*]          := return outputs
        worskpaces.sh --set-focused              := set focus to \${output_key}
        worskpaces.sh --set-scale [--up|--down]  := set output scale (default: reset)
        worskpaces.sh --is-in-ws                 := returns true/false if \${app_name} exists in any workspace
        worskpaces.sh --get-ws [KEY|INT]         := return \${app_name|output_key} workspace
        worskpaces.sh --get-ws-apps [--raw]      := return \${app_name} workspace
        worskpaces.sh --get-ws-focused           := return focused workspace number
        worskpaces.sh --set-ws-focused           := set focus to \$workspace_number

        sourcing:
        get_outputs
        get_outputs_active
        get_outputs_focused
        get_output_config
        set_output_focused
        set_output_scale
        is_in_workspace
        get_workspace
        get_workspaces
        get_workspace_apps
        get_workspace_focused
        set_workspace_focused
EOT
}

workspaces() {
  case "${1-}" in
    --get-containers)
      shift
      get_containers "$@"
      ;;
    --get-active)
      shift
      get_outputs_active "$@"
      ;;
    --get-config)
      shift
      get_output_config "$@"
      ;;
    --get-focused)
      shift
      get_outputs_focused "$@"
      ;;
    --get-from-ws)
      shift
      get_output_from_workspace "$@"
      ;;
    --get-outputs)
      shift
      get_outputs "$@"
      ;;
    --set-focused)
      shift
      set_output_focused "$@"
      ;;
    --set-scale)
      shift
      set_output_scale "$@"
      ;;
    --is-in-ws)
      shift
      is_in_workspace "$@"
      ;;
    --get-ws)
      shift
      get_workspaces "$@"
      ;;
    --get-ws-apps)
      shift
      get_workspace_apps "$@"
      ;;
    --get-ws-focused)
      shift
      get_workspace_focused "$@"
      ;;
    --set-ws-focused)
      shift
      set_workspace_focused "$@"
      ;;
    -h| --help)
      prt_help
      ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  case "${1-}" in
    get_outputs) "$@" ;;
    get_outputs_active) "$@" ;;
    get_outputs_focused) "$@" ;;
    get_output_config) "$@" ;;
    set_output_focused) "$@" ;;
    get_output_from_workspace) "$@" ;;
    set_output_scale) "$@" ;;
    is_in_workspace) "$@" ;;
    get_workspaces)  "$@" ;;
    get_workspace_apps) "$@" ;;
    get_workspace_focused) "$@" ;;
    set_workspace_focused) "$@" ;;
    *) workspaces "$@" ;;
  esac
fi
