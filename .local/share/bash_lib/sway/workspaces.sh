#!/usr/bin/env bash

set -euo pipefail


#----- outputs

# getters

__get_outputs_lite() {
  swaymsg -t get_outputs | jq -r "[ .[] | \
    { name, make, model, serial,
      active, scale, current_workspace, focused,
      default_mode: (.modes[0] | \"\(.width),\(.height),\(.refresh)\"), current_mode, rect } ]"
}

__get_outputs() {
  swaymsg -t get_outputs | jq -r "[ .[] | \
    {
      name, make, model, serial,
      primary, non_desktop,
      power, active,
      focused, current_workspace,
      default_mode: (.modes[0] | \"\(.width),\(.height),\(.refresh)\"),
      perform_mode: (
        .modes as \$modes |
          \$modes[0] as \$ref |
          \$modes |
          map(select(.width == \$ref.width and .height == \$ref.height)) |
          sort_by(-.refresh) | .[0] | \"\(.width),\(.height),\(.refresh)\"
      ),
      current_mode: (
        \"\(.current_mode.width),\(.current_mode.height),\(.current_mode.refresh)\"
      ),
      adaptive_sync_status,
      allow_tearing,
      rect: (
        \"\(.rect.x),\(.rect.y),\(.rect.width),\(.rect.height)\"
      ),
      scale, transform, percent
    }
  ]"
}

__query_outputs() {
  local query=
  if [ -n "${1-}" ]; then query=" | ${1}"; fi
  __get_outputs | jq -r ".[]${query}"
}

__to_monitor_name() {
  printf '%s' "{ monitor_name: \"\(.make) \(.model) \(.serial)\" } | \"\(.monitor_name)\""
}

__to_key_name() {
  printf '%s' "{ name, monitor_name: \"\(.make) \(.model) \(.serial)\" } | \"\(.name)=\(.monitor_name)\""
}

__to_config() {
  printf '%s' "{
    name, monitor_name: \"\(.make) \(.model) \(.serial)\", perform_mode, scale, transform
  } | \"\(.name),\(.monitor_name),\(.perform_mode),\(.scale),\(.transform)\""
}

_query_outputs() {
  local query=
  local pipe=

  [ "${1-}" = "--" ] || query="${1-}"
  shift
  if [ -n "$query" ] && [ -n "${1-}" ]; then pipe=" | "; fi

  case "${1-}" in
    --key)      __query_outputs "${query}${pipe}.name" ;;
    --name)     __query_outputs "${query}${pipe}$(__to_monitor_name)" ;;
    --key-name) __query_outputs "${query}${pipe}$(__to_key_name)" ;;
    --config)   __query_outputs "${query}${pipe}$(__to_config)" ;;
    --raw|*)    __query_outputs "${query}" ;;
  esac
}

query_outputs() {
  _query_outputs "${1:-"--"}" "$@"
}

get_output() {
  local query="select(.name == \"${1-}\" //empty)"
  shift; _query_outputs "$query" "$@"
}

get_output_from_workspace() {
  local query="select(.current_workspace==\"${1-}\" //empty)"
  shift; _query_outputs "$query" "$@"
}

get_outputs() {
  _query_outputs -- "$@"
}

get_outputs_active() {
  local query="select(.active==true)"
  _query_outputs "$query" "$@"
}

get_outputs_focused() {
  local query="select(.focused==true)"
  _query_outputs "$query" "$@"
}

# setters

set_output_focused() {
  printf '%s\n' "$@"
  set -x
  if [ "$(get_outputs | grep -Ewom1 "${1-}" | wc -l)" -gt 0 ]; then
    swaymsg focus output \'"${1-}"\'
  fi
  set +x
}

set_output_scale() {
  [ -z "${1-}" ] && return 1

  local value=0.1
  local curr_scale next_scale
  curr_scale=$(get_output "${1-}" --config | cut -d ',' -f 6)

  case "${2-}" in
    down) next_scale=$(echo "$curr_scale - $value" | bc) ;;
    up)   next_scale=$(echo "$curr_scale + $value" | bc) ;;
    *)    next_scale=1 ;;
  esac

  swaymsg output "${1}" scale "$next_scale"
}


#----- workspaces

# getters

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
  # printf '%s\n' "$@"
  local ws=0
  case "${1-}" in
    --app)
      shift
      # match app_name -> ws
      if is_in_workspace "${1-}"; then
        ws=$(__get_ws_apps | jq -r ". |
          select(limit(1; .representation[][] |
          match(\"^${1-}$\"; \"n\"))) | .name" | sed -Er 's/\"//g;')
        if [ -n "$ws" ]; then
          readarray -t _ws<<<"$ws"
          [ "${#_ws[@]}" -gt 0 ] && { printf "%s\n" "${_ws[0]}" && return; }
        fi
      else false; fi
      ;;
    --output)
      shift
      if [ "$(get_outputs --key | grep -Ewo "^${1-}$" | wc -l)" -gt 0 ]; then
        ws=$(__get_ws_apps | jq -r ". |
          select(limit(1; .output==\"${1-}\")) | .name" |
          sed -Ez 's/\"//g;s/\n$//g;s/\r$//g;s/\n/,/g;s/\r/,/g')
        if [ -n "$ws" ]; then
          readarray -t _ws<<<"$ws"
          [ "${#_ws[@]}" -gt 0 ] && { printf "%s\n" "${_ws[0]}" && return; }
        fi
      else false; fi
      ;;
    --raw|*) __get_ws_apps ;;
  esac
}

get_workspace_apps() {
  __get_ws_apps
}

get_workspace_focused() {
  swaymsg -t get_workspaces | jq '.[] | select(.focused==true) | .num'
}

# setters

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
        [--key]      := 'name'
        [--name]     := 'make model serial'
        [--key-name] := 'name={make model serial}'
        [--config]   := 'name,(make,model,serial),(widths,height,refresh),scale,transform'
        [--raw]      :=  json (default)

        worskpaces.sh -o|--output   [NAME] [ARGS]    := return single output
        worskpaces.sh --from-ws      [INT] [ARGS]    := return output(s) holding \$workspace_number
        worskpaces.sh -O|--outputs  [ARGS]           := return output(s)
        worskpaces.sh --active      [ARGS]           := return active output(s)
        worskpaces.sh --focused     [ARGS]           := return focused output(s)
        worskpaces.sh --query       [JSON] [ARGS]    := return json query'd output(s)

        worskpaces.sh --set-focused               := set focus to \${key|name}
        worskpaces.sh --set-scale [--up|--down]   := set output's scale (empty arg resets)

        worskpaces.sh --is-in-ws             := returns true/false if \${app_name} exists in any workspace
        worskpaces.sh --ws [KEY|INT]         := return \${app_name|output_key} workspace
        worskpaces.sh --ws-apps [--raw]      := return \${app_name} workspace
        worskpaces.sh --ws-focused           := return focused workspace number
        worskpaces.sh --set-ws-focused       := set focus to \$workspace_number

        sourcing:
        get_outputs
        get_outputs_active
        get_outputs_focused
        get_output
        get_output_from_workspace
        set_output_focused
        set_output_scale
        is_in_workspace
        get_workspaces
        get_workspace_apps
        get_workspace_focused
        set_workspace_focused
EOT
}

workspaces() {
  case "${1-}" in
    -o|--output)
      shift
      get_output "$@"
      ;;
    --from-ws)
      shift
      get_output_from_workspace "$@"
      ;;
    -O|--outputs)
      shift
      get_outputs "$@"
      ;;
    --active)
      shift
      get_outputs_active "$@"
      ;;
    --focused)
      shift
      get_outputs_focused "$@"
      ;;
    --query)
      shift
      query_outputs "$@"
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
    -ws|--ws)
      shift
      get_workspaces "$@"
      ;;
    --ws-apps)
      shift
      get_workspace_apps "$@"
      ;;
    --ws-focused)
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

if [ "${#BASH_SOURCE[@]}" -eq 1 ]; then
  case "${1-}" in
    get_output) "$@" ;;
    get_output_from_workspace) "$@" ;;
    get_outputs) "$@" ;;
    get_outputs_active) "$@" ;;
    get_outputs_focused) "$@" ;;
    set_output_focused) "$@" ;;
    set_output_scale) "$@" ;;
    is_in_workspace) "$@" ;;
    get_workspaces)  "$@" ;;
    get_workspace_apps) "$@" ;;
    get_workspace_focused) "$@" ;;
    set_workspace_focused) "$@" ;;
    *) workspaces "$@" ;;
  esac
fi
