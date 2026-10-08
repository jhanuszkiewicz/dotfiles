#!/bin/sh
# bateria - kolor zalezy od poziomu, piorun jak laduje

. "$CONFIG_DIR/colors.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

KOLOR=$GREEN
case "${PERCENTAGE}" in
  9[0-9]|100) ICON=""
  ;;
  [6-8][0-9]) ICON=""
  ;;
  [3-5][0-9]) ICON=""; KOLOR=$YELLOW
  ;;
  [1-2][0-9]) ICON=""; KOLOR=$ORANGE
  ;;
  *) ICON=""; KOLOR=$RED
esac

if [ "$CHARGING" != "" ]; then
  ICON=""
  KOLOR=$GREEN
fi

sketchybar --set "$NAME" icon="$ICON" icon.color=$KOLOR label="${PERCENTAGE}%"
