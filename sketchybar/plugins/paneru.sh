#!/bin/bash
# $1 = numer workspace z sketchybarrc

PANERU=/opt/homebrew/bin/paneru
[ -x $PANERU ] || PANERU=$HOME/.cargo/bin/paneru

if [ -z "$FOCUSED_WORKSPACE" ]; then
  FOCUSED_WORKSPACE=$($PANERU query active --json 2>/dev/null | sed -n 's/.*"virtual_workspace_number":\([0-9]*\).*/\1/p')
fi

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME background.drawing=on icon.highlight=on
else
  sketchybar --set $NAME background.drawing=off icon.highlight=off
fi
