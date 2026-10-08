#!/bin/sh
# battery - plain, red only when low

. "$CONFIG_DIR/colors.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

ICON=""
COL=$FG
if [ "$PERCENTAGE" -lt 20 ]; then
  ICON=""
  COL=$RED
fi
if [ "$CHARGING" != "" ]; then
  ICON=""
fi

sketchybar --set "$NAME" icon="$ICON" icon.color=$COL label="${PERCENTAGE}%" label.color=$COL
