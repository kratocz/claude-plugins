#!/usr/bin/env bash
# Shared notification helpers for desktop-notify plugin.
# Reads DESKTOP_NOTIFY_METHOD env var: visual (default) | sound | both

_dn_visual() {
  local title="$1" msg="$2" urgency="${3:-normal}"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e "display notification \"$msg\" with title \"$title\"" 2>/dev/null
  elif command -v notify-send &>/dev/null; then
    notify-send "$title" "$msg" -u "$urgency" 2>/dev/null
  fi
}

_dn_sound() {
  local title="$1" msg="$2"
  local text="$title. $msg"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    say "$text" &
  elif command -v spd-say &>/dev/null; then
    spd-say "$text" &
  elif command -v espeak-ng &>/dev/null; then
    espeak-ng "$text" &
  elif command -v espeak &>/dev/null; then
    espeak "$text" &
  fi
}

# notify TITLE MSG [URGENCY]
# URGENCY: normal (default) | critical — used only for visual notifications
notify() {
  local title="$1" msg="$2" urgency="${3:-normal}"
  case "${DESKTOP_NOTIFY_METHOD:-visual}" in
    sound) _dn_sound "$title" "$msg" ;;
    both)  _dn_visual "$title" "$msg" "$urgency"; _dn_sound "$title" "$msg" ;;
    *)     _dn_visual "$title" "$msg" "$urgency" ;;
  esac
}
