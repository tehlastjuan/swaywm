#!/usr/bin/env bash

#----- outputs & monitors

get_outputs() {
  swaymsg -t get_outputs | jq -r "[ .[] | { name, make, model, serial, active, current_workspace, default_mode: (.modes[0] | \"\(.width),\(.height),\(.refresh)\"), current_mode, rect } ]"
}

get_monitor_name_list() {
  get_outputs | jq -r '[ .[] | { make, model, serial } ] | .[] | "\(.make) \(.model) \(.serial)"'
}

get_outputs_name_model() {
  get_outputs | jq -r ".[] | { name, monitor_name: \"\(.make) \(.model) \(.serial)\" } | \"\(.name)=\(.monitor_name)\""
}

get_active_outputs() {
  get_outputs | jq -r ".[] | { name, monitor_name: \"\(.make) \(.model) \(.serial)\", active } | select(.active == true) | \"\(.name)=\(.monitor_name)\""
}

get_active_output() {
  swaymsg -t get_workspaces | jq '.[] | select(.focused==true) | .output' | sed 's/"//g'
}

get_output_config() {
  get_outputs | jq -r ". [] | select(.name == \"${1-}\" //empty) | \"\(.name),\(.make) \(.model) \(.serial),\(.default_mode)\""

}

#----- workspaces

is_in_workspace() {
  if [ -n "$(swaymsg -t get_workspaces | jq -r ". [] | {id, name, representation: (.representation | match(\"${1-}\"))} | .name")" ]
  then return; fi
  false
}

get_ws_number() {
  if is_in_workspace "${1-}"; then
    swaymsg -t get_workspaces | jq -r ". [] | {id, name, representation: (.representation | match(\"${1-}\"))} | .name"
  fi
  false
}

get_focused_ws() {
  swaymsg -t get_workspaces | jq '.[] | select(.focused==true) | .num'
}
