#!/usr/bin/env bash

function pass() {
  if ! command -v keepassxc &> /dev/null; then return 1; fi

  case "${1-}" in
    --clear)
      if pgrep keepassxc; then
        pkill keepassxc
      fi
    ;;
    *)
      if pgrep keepassxc; then
        swaymsg '[app_id="org.keepassxc.KeePassXC"]' focus
      else
        nohup keepassxc &> /dev/null &
      fi
    ;;
  esac
}

if [ "${#BASH_SOURCE[@]}" -eq 1 ]; then
  pass "$@"
fi
