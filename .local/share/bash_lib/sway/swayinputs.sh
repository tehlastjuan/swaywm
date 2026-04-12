#!/usr/bin/env bash

# set -x

declare -a OUTPUT_OPT=()
declare -a INPUTS_CMD=()

__get_inputs() {
  swaymsg -t get_inputs --raw | jq -r "[ .[] |
    {
      id: ( \"\(.vendor):\(.product)\" ),
      identifier,
      name,
      type,
      libinput
    }
  ]"
}

init_inputs_cmd() {
  if [ "${#INPUTS_CMD[@]}" -eq 0 ]; then
    INPUTS_CMD=(
      'swaymsg -t get_inputs --raw'
      ' | jq -r " [ .[]'
      ' | { id: ( \"\(.vendor):\(.product)\" ), identifier, name, type, libinput } ]"'
    )
  fi
}

add_to_inputs_cmd() {
  [ "${#INPUTS_CMD[@]}" -eq 0 ] && init_inputs_cmd
  INPUTS_CMD+=(' | jq -r "')
  INPUTS_CMD+=("${1-}")
  INPUTS_CMD+=('"')
}

#----- args

get_inputs_id() {
  __coerce_int() {
    printf '%d' $(( 10#${1:-0} ))
  }

  local -a inputs=()
  readarray -td ',' inputs < <(printf '%s' "${1-}")
  shift

  local -a expr=('\"')
  case "${#inputs[@]}" in
    1)
      if [ -z "${inputs[0]-}" ]; then
        expr+=("^[0-9]+:[0-9]+")
      else
        expr+=("^")
        expr+=("$(__coerce_int "${inputs[0]-}")")
        expr+=(":")
        expr+=("[")
        expr+=("0")
        expr+=("-")
        expr+=("9")
        expr+=("]")
        expr+=("+")
      fi
      ;;
    2|*)
      expr+=("^")
      expr+=("$(__coerce_int "${inputs[0]-}")")
      expr+=(":")
      expr+=("$(__coerce_int "${inputs[1]-}")")
      ;;
  esac
  expr+=('\"')

  add_to_inputs_cmd "[ .[] | select(.id | test(\"$(printf '%s' "${expr[@]}")\")) ]"
}

get_inputs_type() {
  local -a type_cmd=()
  local type="${1-}"
  shift

  if [ -z "$type" ]; then
    type_cmd+=('[ .[] | .type ] | unique')
  else
    type_cmd+=('[ .[] | select(.type==\"')
    type_cmd+=("${type}")
    type_cmd+=('\") ]')
  fi

  add_to_inputs_cmd "$(printf '%s' "${type_cmd[@]}")"
}

get_inputs_grep() {
  local -a expr=('\"')
  expr+=("${1-}")
  expr+=('\"')
  shift
  add_to_inputs_cmd "[ .[] | select(.identifier | test(\"$(printf '%s' "${expr[@]}")\")) ]"
}

format_output() {
  [ -z "${1-}" ] && return

  local -a opts=()
  readarray -td ',' opts < <(printf '%s' "${1-}")
  shift

  local -a _obj_json=('{ ')
  local -a _obj_prnt=('\"')
  for i in "${!opts[@]}"; do
    if [ "$i" -eq 0 ]; then
      _obj_json+=("${opts[$i]}")
      _obj_prnt+=('\(')
      _obj_prnt+=(".${opts[$i]}")
      _obj_prnt+=(')')
    else
      _obj_json+=(", ${opts[$i]}")
      _obj_prnt+=(',\(')
      _obj_prnt+=(".${opts[$i]}")
      _obj_prnt+=(')')
    fi
  done
  _obj_json+=(' }')
  _obj_prnt+=('\"')

  local -a _cmd=()
  _cmd+=(' | jq -r "[ .[] | ')
  _cmd+=("$(printf '%s' "${_obj_json[@]}")")
  _cmd+=(' | ')
  _cmd+=("$(printf '%s' "${_obj_prnt[@]}")")
  _cmd+=(']"')

  OUTPUT_OPT+=("$(printf '%s' "${_cmd[@]}")")
}

run_cmd() {
  init_inputs_cmd

  local -a _cmd=()
  for i in "${!INPUTS_CMD[@]}"; do
    _cmd+=("${INPUTS_CMD[$i]}")
  done
  for i in "${!OUTPUT_OPT[@]}"; do
    _cmd+=("${OUTPUT_OPT[$i]}")
  done
  # _cmd+=('"')

  printf '%s' "${_cmd[@]}"
}

swayinputs() {
  # __get_inputs
  # return

  while true; do
    [ $# -eq 0 ] && break
    case "${1-}" in
      --)
        break
        ;;
      -o|--output)
        shift
        format_output "$@"
        ;;
      -t|--type)
        shift
        get_inputs_type "$@"
        ;;
      --id)
        shift
        get_inputs_id "$@"
        ;;
      -g|--grep)
        shift
        get_inputs_grep "$@"
        ;;
    esac
    shift
  done

  #run_cmd
  bash -c "$(run_cmd)"
}

if [ "${#BASH_SOURCE[@]}" -eq 1 ]; then
  swayinputs "$@"
fi
