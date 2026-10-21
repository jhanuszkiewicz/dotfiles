#!/bin/bash
# $1 = numer workspace z sketchybarrc

if [ -z "$FOCUSED_WORKSPACE" ]; then
  FOCUSED_WORKSPACE=$(/opt/homebrew/bin/aerospace list-workspaces --focused)
fi

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME background.drawing=on icon.highlight=on
else
  sketchybar --set $NAME background.drawing=off icon.highlight=off
fi
