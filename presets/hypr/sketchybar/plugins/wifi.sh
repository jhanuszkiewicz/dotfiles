#!/bin/bash
# wifi - icon only, grey when connected, red when not

. "$CONFIG_DIR/colors.sh"

ip=$(ipconfig getifaddr en0)

if [ -z "$ip" ]; then
  sketchybar --set "$NAME" icon=󰖪 icon.color=$RED
else
  sketchybar --set "$NAME" icon=󰖩 icon.color=$GREY
fi
