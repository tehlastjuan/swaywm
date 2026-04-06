#!/usr/bin/env bash

pass() {
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
        if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
          keepassxc
        else
          nohup keepassxc &> /dev/null &
        fi
      fi
    ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  pass "$@"
fi
