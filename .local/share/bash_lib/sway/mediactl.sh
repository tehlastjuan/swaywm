#!/usr/bin/env bash
# shellcheck disable=1091,2034

source /usr/local/bin/userenv export_env BASH_LIB
source "${BASH_LIB}/sway/wobctl.sh"

# https://blog.bootkit.dev/post/nix-extravaganza-thinkpad-t14-gen5-amd/
LED_BRIGHTNESS="/sys/class/leds/platform::micmute/brightness"

#----- mic led

src_status() {
  pactl get-source-mute @DEFAULT_SOURCE@ | sed -n 's/Mute: //Ip;d'
}

toggle_led() {
  if [[ "$HOSTNAME" == 21* ]]; then
    local mic_status
    mic_status=$(src_status)
    [ "$mic_status" == 'yes' ] && { (echo 1 > "$LED_BRIGHTNESS") && return; }
    [ "$mic_status" == 'no' ] && { (echo 0 > "$LED_BRIGHTNESS") && return; }
  fi
}


#----- speakers controls

sink_vol() {
  pactl get-sink-volume @DEFAULT_SINK@ | grep '^Volume:' | cut -d / -f 2 | tr -d ' ' | sed 's/%//'
}

sink_toggle() {
  pactl set-sink-mute @DEFAULT_SINK@ toggle && 
    pactl get-sink-mute @DEFAULT_SINK@ |
    sed -En "/no/ s/.*/$(sink_vol)/p; /yes/ s/.*/0/p"
  show_wob "$(pactl get-sink-mute @DEFAULT_SINK@ |
    sed -En "/no/ s/.*/$(sink_vol)/p; /yes/ s/.*/0/p")"
}

sink_mute() {
  pactl set-sink-mute @DEFAULT_SOURCE@ true
}

sink_unmute() {
  pactl set-sink-mute @DEFAULT_SOURCE@ false
}

sink_vol_up() {
  pactl set-sink-volume @DEFAULT_SINK@ +1% && "$(sink_vol)"
  show_wob "$(sink_vol)"
}

sink_vol_down() {
  pactl set-sink-volume @DEFAULT_SINK@ -1% && "$(sink_vol)"
  show_wob "$(sink_vol)"
}


#----- mic controls

src_vol() {
  pactl get-source-volume @DEFAULT_SOURCE@ | grep '^Volume:' | cut -d / -f 2 | tr -d ' ' | sed 's/%//'
}

src_toggle() {
  pactl set-source-mute @DEFAULT_SOURCE@ toggle &&
    pactl get-source-mute @DEFAULT_SOURCE@ |
    sed -En "/no/ s/.*/$(src_vol)/p; /yes/ s/.*/0/p"
  show_wob "$(pactl get-source-mute @DEFAULT_SOURCE@ |
    sed -En "/no/ s/.*/$(src_vol)/p; /yes/ s/.*/0/p")"
  toggle_led
}

src_mute() {
  pactl set-source-mute @DEFAULT_SOURCE@ true
  toggle_led
}

src_unmute() {
  pactl set-source-mute @DEFAULT_SOURCE@ false
  toggle_led
}

src_vol_up() {
  pactl set-source-volume @DEFAULT_SOURCE@ +1% && "$(src_vol)"
  show_wob "$(src_vol)"
}

src_vol_down() {
  pactl set-source-volume @DEFAULT_SOURCE@ -1% && "$(src_vol)"
  show_wob "$(src_vol)"
}

_prt_mediactl_info() {
  cat << EOF
usage: mediactl.sh [IFACE] [ARG]
       mediactl.sh [--sink|-sink] mute
       mediactl.sh [--sink|-sink] unmute
       mediactl.sh [--sink|-sink] toggle
       mediactl.sh [--sink|-sink] up
       mediactl.sh [--sink|-sink] down
       mediactl.sh [--source|-src] mute
       mediactl.sh [--source|-src] unmute
       mediactl.sh [--source|-src] toggle
       mediactl.sh [--source|-src] up
       mediactl.sh [--source|-src] down
EOF
}

_mediactl() {
  case "${1:-''}" in
    --source | -src)
      case "${2-''}" in
        mute)   src_mute ;;
        unmute) src_unmute ;;
        toggle) src_toggle ;;
        up)     src_vol_up ;;
        down)   src_vol_down ;;
        *)      _prt_mediactl_info ;;
    esac
    ;;
    --sink | -sink)
      case "${2-''}" in
        mute)   sink_mute ;;
        unmute) sink_unmute ;;
        toggle) sink_toggle ;;
        up)     sink_vol_up ;;
        down)   sink_vol_down ;;
        *)      _prt_mediactl_info ;;
    esac
    ;;
    *)          _prt_mediactl_info ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  _mediactl "$@"
fi
