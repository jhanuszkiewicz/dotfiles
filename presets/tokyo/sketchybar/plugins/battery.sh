#!/bin/bash
# battery - classic horizontal icon, number of bars depends on the level
# grey normally, yellow below 20%, red below 10%, green when charging
# percentage always next to it (colored only when low)

. "$CONFIG_DIR/colors.sh"

PROC="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
LADUJE="$(pmset -g batt | grep 'AC Power')"

if [ "$PROC" = "" ]; then
  exit 0
fi

case "$PROC" in
  9[0-9]|100) IKONA="" ;;
  [6-8][0-9]) IKONA="" ;;
  [3-5][0-9]) IKONA="" ;;
  [1-2][0-9]) IKONA="" ;;
  *) IKONA="" ;;
esac

kolor=$GREY
if [ "$LADUJE" != "" ]; then
  kolor=$GREEN
elif [ $PROC -le 10 ]; then
  kolor=$RED
elif [ $PROC -le 20 ]; then
  kolor=$YELLOW
fi

lkolor=$FG2
if [ "$kolor" = "$RED" ] || [ "$kolor" = "$YELLOW" ]; then
  lkolor=$kolor
fi

sketchybar --set battery icon="$IKONA" icon.color=$kolor label="${PROC}%" label.color=$lkolor
