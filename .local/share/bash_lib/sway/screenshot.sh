#!/usr/bin/env bash

source /usr/local/bin/userenv --

set -euo pipefail

function kill_screenshots_monitor() {
  if [ -n "$(pgrep -f "inotifywait -q --monitor $XDG_SCREENSHOTS_DIR")" ]; then
    kill "$(pgrep -f "inotifywait -q --monitor $HOME/.screenshots")"
  fi
}

function start_monitor_screenshots() {
  kill_screenshots_monitor

  inotifywait -q --monitor "$HOME/.screenshots" | while read -r _ event name; do
    case $event in
      CREATE*) userexec notify-send "Screenshot saved: '$name'" ;;
      *) ;;
    esac
  done
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  start_screenshots_monitor
fi
