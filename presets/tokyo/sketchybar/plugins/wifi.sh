#!/bin/sh
# ikonka wifi + nazwa sieci jesli macos ja w ogole poda

. "$CONFIG_DIR/colors.sh"

ip=$(ipconfig getifaddr en0)

if [ -z "$ip" ]; then
  sketchybar --set "$NAME" icon=󰖪 icon.color=$RED label.drawing=off
  exit 0
fi

# od sequoi apple zwykle ukrywa ssid (<redacted>), wtedy sama ikonka
ssid=$(ipconfig getsummary en0 | awk -F ' SSID : ' '/ SSID : / {print $2}')

case "$ssid" in
  ""|*redacted*)
    sketchybar --set "$NAME" icon=󰖩 icon.color=$CYAN label.drawing=off
    ;;
  *)
    sketchybar --set "$NAME" icon=󰖩 icon.color=$CYAN label="$ssid" label.drawing=on
    ;;
esac
