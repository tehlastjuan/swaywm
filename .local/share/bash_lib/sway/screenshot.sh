#!/usr/bin/env bash

source /usr/local/bin/userenv

set -euo pipefail

kill_monitor() {
  if [ -n "$(pgrep -f "inotifywait -q --monitor $_HOME/.screenshots")" ]; then
    kill "$(pgrep -f "inotifywait -q --monitor $_HOME/.screenshots")"
  fi
}

monitor_screenshots() {
  local event
  local name

  inotifywait -q --monitor "$_HOME/.screenshots" | while read -r _ event name; do
    case $event in
      CREATE*) userexec notify-send "Screenshot saved: '$name'" ;;
      *) ;;
    esac
  done
}

_screenshots() {
  kill_monitor
  monitor_screenshots
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _screenshots
fi
