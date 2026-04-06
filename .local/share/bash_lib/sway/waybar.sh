#!/usr/bin/env bash

source /usr/local/bin/userenv --

pkill -U "$_USER" -x waybar

sass "${DOT_FILES}/${HOSTNAME}/.config/waybar/style.scss" "${DOT_FILES}/${HOSTNAME}/.config/waybar/style.css"

waybar
