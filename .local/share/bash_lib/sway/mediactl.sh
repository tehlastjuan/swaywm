#!/usr/bin/env bash
# shellcheck disable=1091,2034

source /usr/local/bin/userenv --
source "${BASH_LIB}/sway/wobctl.sh"

# https://blog.bootkit.dev/post/nix-extravaganza-thinkpad-t14-gen5-amd/
VOL_LED_BRIGHTNESS="/sys/class/leds/platform::mute/brightness"
MIC_LED_BRIGHTNESS="/sys/class/leds/platform::micmute/brightness"

#----- mic led

sink_status() {
  pactl get-sink-mute @DEFAULT_SINK@ | sed -n 's/Mute: //Ip;d'
}

src_status() {
  pactl get-source-mute @DEFAULT_SOURCE@ | sed -n 's/Mute: //Ip;d'
}

toggle_vol_led() {
  if [[ "$HOSTNAME" == 21* ]]; then
    local vol_status
    vol_status=$(sink_status)
    [ "$vol_status" == 'yes' ] && { (echo 1 > "$VOL_LED_BRIGHTNESS") && return; }
    [ "$vol_status" == 'no' ] && { (echo 0 > "$VOL_LED_BRIGHTNESS") && return; }
  fi
}

toggle_mic_led() {
  if [[ "$HOSTNAME" == 21* ]]; then
    local mic_status
    mic_status=$(src_status)
    [ "$mic_status" == 'yes' ] && { (echo 1 > "$MIC_LED_BRIGHTNESS") && return; }
    [ "$mic_status" == 'no' ] && { (echo 0 > "$MIC_LED_BRIGHTNESS") && return; }
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
  wobctl --show "$(pactl get-sink-mute @DEFAULT_SINK@ |
    sed -En "/no/ s/.*/$(sink_vol)/p; /yes/ s/.*/0/p")"
  toggle_vol_led
}

sink_mute() {
  pactl set-sink-mute @DEFAULT_SOURCE@ true
  toggle_vol_led
}

sink_unmute() {
  pactl set-sink-mute @DEFAULT_SOURCE@ false
  toggle_vol_led
}

sink_vol_up() {
  pactl set-sink-volume @DEFAULT_SINK@ +1% && "$(sink_vol)"
  wobctl --show "$(sink_vol)"
}

sink_vol_down() {
  pactl set-sink-volume @DEFAULT_SINK@ -1% && "$(sink_vol)"
  wobctl --show "$(sink_vol)"
}


#----- mic controls

src_vol() {
  pactl get-source-volume @DEFAULT_SOURCE@ | grep '^Volume:' | cut -d / -f 2 | tr -d ' ' | sed 's/%//'
}

src_toggle() {
  pactl set-source-mute @DEFAULT_SOURCE@ toggle &&
    pactl get-source-mute @DEFAULT_SOURCE@ |
    sed -En "/no/ s/.*/$(src_vol)/p; /yes/ s/.*/0/p"
  wobctl --show "$(pactl get-source-mute @DEFAULT_SOURCE@ |
    sed -En "/no/ s/.*/$(src_vol)/p; /yes/ s/.*/0/p")"
  toggle_mic_led
}

src_mute() {
  pactl set-source-mute @DEFAULT_SOURCE@ true
  toggle_mic_led
}

src_unmute() {
  pactl set-source-mute @DEFAULT_SOURCE@ false
  toggle_mic_led
}

src_vol_up() {
  pactl set-source-volume @DEFAULT_SOURCE@ +1% && "$(src_vol)"
  wobctl --show "$(src_vol)"
}

src_vol_down() {
  pactl set-source-volume @DEFAULT_SOURCE@ -1% && "$(src_vol)"
  wobctl --show "$(src_vol)"
}

prt_mediactl_info() {
  cat << EOF
usage: mediactl.sh [FLAG+ARG]
       mediactl.sh [-k|--sink] down
       mediactl.sh [-k|--sink] mute
       mediactl.sh [-k|--sink] toggle
       mediactl.sh [-k|--sink] unmute
       mediactl.sh [-k|--sink] up
       mediactl.sh [-s|--source] down
       mediactl.sh [-s|--source] mute
       mediactl.sh [-s|--source] toggle
       mediactl.sh [-s|--source] unmute
       mediactl.sh [-s|--source] up
EOF
}

mediactl() {
  case "${1-}" in
    -h|--help)
      prt_mediactl_info
      ;;
    -k|--sink)
      shift
      case "${1-}" in
        mute)   sink_mute ;;
        unmute) sink_unmute ;;
        toggle) sink_toggle ;;
        up)     sink_vol_up ;;
        down)   sink_vol_down ;;
        *)      prt_mediactl_info ;;
      esac
      ;;
    -s|--source)
      shift
      case "${1-}" in
        mute)   src_mute ;;
        unmute) src_unmute ;;
        toggle) src_toggle ;;
        up)     src_vol_up ;;
        down)   src_vol_down ;;
        *)      prt_mediactl_info ;;
      esac
      ;;
  esac
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
  mediactl "$@"
fi
