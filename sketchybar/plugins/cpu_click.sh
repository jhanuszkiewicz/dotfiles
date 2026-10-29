#!/bin/bash
# click on cpu: popup with the top processes by cpu, a second click switches it
# to ram, a third closes it (cpu.sh keeps the list fresh while it's open)
# right click = btop (if the preset has it)

export PATH=/opt/homebrew/bin:$PATH

if [ "$BUTTON" = "right" ] && [ -x "$CONFIG_DIR/plugins/btop_toggle.sh" ]; then
  "$CONFIG_DIR/plugins/btop_toggle.sh"
  exit 0
fi

plik="/tmp/sketchybar_cpu_$USER"

if [ "$(sketchybar --query cpu_icon | jq -r '.popup.drawing')" != "on" ]; then
  tryb=cpu
elif [ "$(cat "$plik" 2>/dev/null)" = "cpu" ]; then
  tryb=ram
else
  echo off > "$plik"
  sketchybar --set cpu_icon popup.drawing=off
  exit 0
fi

echo $tryb > "$plik"
"$CONFIG_DIR/plugins/cpu_top.sh" $tryb
sketchybar --set cpu_icon popup.drawing=on
