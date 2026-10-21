#!/bin/bash
# volume: icon + slider
# the slider only shows the level - on change the notch island pops up (island.sh)

. "$CONFIG_DIR/colors.sh"

if [ "$SENDER" = "volume_change" ]; then
  VOL="$INFO"
else
  VOL=$(osascript -e 'output volume of (get volume settings)')
fi

case "$VOL" in
  [6-9][0-9]|100) IKONA="󰕾" ;;
  [3-5][0-9]) IKONA="󰖀" ;;
  [1-9]|[1-2][0-9]) IKONA="󰕿" ;;
  *) IKONA="󰖁" ;;
esac

sketchybar --set vol_icon icon="$IKONA" \
  --set volume slider.percentage=$VOL \
  --set vol_txt label="$VOL%"
