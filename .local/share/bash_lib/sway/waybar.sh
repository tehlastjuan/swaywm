#!/usr/bin/env bash

source /usr/local/bin/userenv --

pkill -U "$_USER" -x waybar

sass "${DOTFILES}/${HOSTNAME}/.config/waybar/style.scss" "${DOTFILES}/${HOSTNAME}/.config/waybar/style.css"

waybar
