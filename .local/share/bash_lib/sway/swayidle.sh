#!/usr/bin/env bash

source /usr/local/bin/userenv --

IDLE_TIMEOUT=240
LOCK_TIMEOUT=300
SCREEN_TIMEOUT=420
SLEEP_TIMEOUT=900

if pgrep 'swayidle'; then pkill --oldest 'swayidle' &> /dev/null; fi

swayidle -w \
  timeout "$IDLE_TIMEOUT" 'brightnessctl -s && brightnessctl set 30%', resume 'brightnessctl -r' \
  timeout "$LOCK_TIMEOUT" "if ! pgrep 'swaylock'; then logger 'SWAYIDLE: locktimeout'; $BASH_LIB/sway/swaylock.sh && sleep 2; fi" \
  timeout "$SCREEN_TIMEOUT" 'swaymsg "output * dpms off"', resume 'swaymsg "output * dpms on"' \
  timeout "$SLEEP_TIMEOUT" "swaymsg \"output \* dpms off\"; if ! pgrep 'swaylock'; logger 'SWAYIDLE: sleep-timeout'; then $BASH_LIB/sway/swaylock.sh && sleep 2; fi" \
  before-sleep "if ! pgrep 'swaylock'; then logger 'SWAYIDLE: before-sleep'; $BASH_LIB/sway/swaylock.sh && sleep 2; fi" \
  after-resume 'swaymsg "output * dpms on\" && brightnessctl -r'
