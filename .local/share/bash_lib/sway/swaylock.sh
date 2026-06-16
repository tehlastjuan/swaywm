#!/usr/bin/env bash

waylock -fork-on-lock \
    -init-color 0x1e222a \
    -input-color 0x2d3343 \
    -fail-color 0xe06c75


#logger "swaylock.sh: $(pgrep 'swaylock')"
# if ! pgrep 'swaylock'; then
#   swaylock --daemonize                                \
#     --line-uses-ring                                  \
#     --show-failed-attempts                            \
#     --ignore-empty-password                           \
#     --screenshots                                     \
#     --hide-keyboard-layout                            \
#     --fade-in               0                         \
#     --grace                 0                         \
#     --indicator-radius      90                        \
#     --indicator-thickness   20                        \
#     --effect-pixelate       20                        \
#     --effect-vignette       0.4:0.4                   \
#     --font                  "IosevkaCustom Nerd Font" \
#     --font-size             20                        \
#     --line-color            00000000                  \
#     --ring-color            00000000                  \
#     --ring-clear-color      00000000                  \
#     --ring-wrong-color      e06c75FF                  \
#     --ring-ver-color        c678ddFF                  \
#     --inside-color          00000000                  \
#     --inside-clear-color    00000000                  \
#     --inside-ver-color      00000000                  \
#     --inside-wrong-color    00000000                  \
#     --key-hl-color          56b6c2FF                  \
#     --bs-hl-color           c678ddFF                  \
#     --text-color            00000000                  \
#     --text-clear-color      00000000                  \
#     --text-wrong-color      00000000                  \
#     --text-ver-color        00000000                  \
#     --separator-color       00000000
# fi

# pkill --oldest 'swaylock'
# logger "swaylock.sh: after kill swaylock"

