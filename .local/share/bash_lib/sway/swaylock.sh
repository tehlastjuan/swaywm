#!/usr/bin/env bash

set -euo pipefail

_run_swaylock_daemon() {
  swaylock --daemonize                                \
    --line-uses-ring                                  \
    --show-failed-attempts                            \
    --ignore-empty-password                           \
    --screenshots                                     \
    --hide-keyboard-layout                            \
    --fade-in               0                         \
    --grace                 0                         \
    --indicator-radius      90                        \
    --indicator-thickness   20                        \
    --effect-pixelate       20                        \
    --effect-vignette       0.4:0.4                   \
    --font                  "IosevkaCustom Nerd Font" \
    --font-size             20                        \
    --line-color            00000000                  \
    --ring-color            00000000                  \
    --ring-clear-color      00000000                  \
    --ring-wrong-color      e06c75FF                  \
    --ring-ver-color        c678ddFF                  \
    --inside-color          00000000                  \
    --inside-clear-color    00000000                  \
    --inside-ver-color      00000000                  \
    --inside-wrong-color    00000000                  \
    --key-hl-color          56b6c2FF                  \
    --bs-hl-color           c678ddFF                  \
    --text-color            00000000                  \
    --text-clear-color      00000000                  \
    --text-wrong-color      00000000                  \
    --text-ver-color        00000000                  \
    --separator-color       00000000
}

_run_swaylock_process() {
  swaylock                                            \
    --line-uses-ring                                  \
    --show-failed-attempts                            \
    --ignore-empty-password                           \
    --screenshots                                     \
    --hide-keyboard-layout                            \
    --fade-in               0                         \
    --grace                 0                         \
    --indicator-radius      90                        \
    --indicator-thickness   20                        \
    --effect-pixelate       20                        \
    --effect-vignette       0.4:0.4                   \
    --font                  "IosevkaCustom Nerd Font" \
    --font-size             20                        \
    --line-color            00000000                  \
    --ring-color            00000000                  \
    --ring-clear-color      00000000                  \
    --ring-wrong-color      e06c75FF                  \
    --ring-ver-color        c678ddFF                  \
    --inside-color          00000000                  \
    --inside-clear-color    00000000                  \
    --inside-ver-color      00000000                  \
    --inside-wrong-color    00000000                  \
    --key-hl-color          56b6c2FF                  \
    --bs-hl-color           c678ddFF                  \
    --text-color            00000000                  \
    --text-clear-color      00000000                  \
    --text-wrong-color      00000000                  \
    --text-ver-color        00000000                  \
    --separator-color       00000000
}

_swaylock() {
  case "${1:-''}" in
    --process)   _run_swaylock_process ;;
    --daemon|*)  _run_swaylock_daemon ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _swaylock "$@"
fi
