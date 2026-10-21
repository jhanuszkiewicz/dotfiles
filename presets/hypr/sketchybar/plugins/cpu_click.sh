#!/bin/bash
# click on cpu: the icon turns into a graph for 8 s, a second click goes back right away
# right click = btop (if the preset has it)

export PATH=/opt/homebrew/bin:$PATH

if [ "$BUTTON" = "right" ] && [ -x "$CONFIG_DIR/plugins/btop_toggle.sh" ]; then
  "$CONFIG_DIR/plugins/btop_toggle.sh"
  exit 0
fi

plik="/tmp/sketchybar_cpu_$USER"

# graph already shown - hide it right away
if [ "$(sketchybar --query cpu | jq -r '.geometry.drawing')" = "on" ]; then
  echo nic > "$plik"
  sketchybar --set cpu drawing=off --set cpu_icon drawing=on
  exit 0
fi

sketchybar --set cpu_icon drawing=off --set cpu drawing=on

# icon back after 8 s (unless there was another click meanwhile)
echo $$ > "$plik"
(
  sleep 8
  if [ "$(cat "$plik")" = "$$" ]; then
    sketchybar --set cpu drawing=off --set cpu_icon drawing=on
  fi
) &
