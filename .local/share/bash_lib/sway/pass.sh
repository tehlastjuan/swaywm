#!/usr/bin/env bash

_pass() {
  if pgrep keepassxc; then
    swaymsg '[app_id="org.keepassxc.KeePassXC"]' focus
  else keepassxc; fi
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _pass
fi
