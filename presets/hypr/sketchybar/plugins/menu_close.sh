#!/bin/bash
# closes our dropdown (mouse left the bar, app switched, item picked, title clicked again)
# and puts the titles back to normal

source "$CONFIG_DIR/colors.sh"

rm -f "/tmp/sketchybar_menu_open_$USER"
sketchybar --remove '/mpop\..*/' \
  --set '/menu\.[0-9][0-9]*/' popup.drawing=off \
    background.color=$BG2 background.height=24 background.corner_radius=6 label.color=$FG2 \
    background.drawing=off \
  --set menu.1 label.color=$FG
