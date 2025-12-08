#!/usr/bin/env bash

_pass() {
  case "${1:-''}" in
    --clear) 
      if pgrep keypassxc; then
        pkill keypassxc
      fi
    ;;
    *)
      if pgrep keepassxc; then
        swaymsg '[app_id="org.keepassxc.KeePassXC"]' focus
      else
        keepassxc
      fi
    ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _pass
fi
