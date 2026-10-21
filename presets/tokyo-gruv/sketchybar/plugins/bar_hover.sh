#!/bin/bash
# transparent bar, but when the cursor hits the top of the screen
# (that's when macos slides in its menubar) it turns black and covers it

. "$CONFIG_DIR/colors.sh"

NORMALNIE=0x00000000
NAJECHANY=$CZARNY

if [ "$SENDER" = "mouse.entered.global" ]; then
  sketchybar --animate tanh 8 --bar color=$NAJECHANY
elif [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --animate tanh 20 --bar color=$NORMALNIE
fi
