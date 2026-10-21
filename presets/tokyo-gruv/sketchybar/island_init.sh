#!/bin/bash
# dynamic island around the notch - sourced at the end of sketchybarrc
#
# q / e = items glued to the left / right side of the notch. hidden at rest,
# plugins/island.sh shows them and grows them (animated) when something happens -
# the left half grows to the left, the right half to the right. an item is never
# narrower than its content, so when closed the text widths and paddings are 0
# and island.sh animates those, not the item width each half has its own black background; the inner corners go under
# the real notch (notch_width below is smaller than the real one), so the two
# halves + the notch look like one black shape

# smaller than the real notch, so both halves slide in under it
# (gap between the notch and the island -> make it smaller, and raise ZAPAS
# in plugins/island.sh by half of the change, so the text stays in place)
NOTCH=130
sketchybar --bar notch_width=$NOTCH

# TEMP debug log for the island (delete later)
mkdir -p "$HOME/.dotfiles/.debug"
ISLAND_LOG="$HOME/.dotfiles/.debug/island.log"
echo "=== init $(date)" > "$ISLAND_LOG"

sketchybar --add event island_cmd \
  --add event island_media \
  --add event island_pomodoro >> "$ISLAND_LOG" 2>&1

# island shape, it has to stay inside the 38 pt bar (taller backgrounds aren't drawn):
#   each half = black box from the top of the screen down to 32 pt, rounded corners
#   island_top = flat black strip along the top edge over both halves, so the top
#   corners are square and only the bottom ones are rounded (like the notch)
# Y_ZNAK = 1 if a positive y_offset moves things up, -1 if down
Y_ZNAK=1
ISLAND_BG="background.drawing=on background.color=0xff000000 background.height=32 background.y_offset=$(( 3 * Y_ZNAK )) background.corner_radius=8 icon.y_offset=$(( 3 * Y_ZNAK )) label.y_offset=$(( 3 * Y_ZNAK ))"

sketchybar --add item island.l q \
  --set island.l drawing=off width=dynamic padding_left=0 padding_right=0 \
    icon.padding_left=0 icon.padding_right=0 icon.width=0 \
    icon.font="JetBrainsMono Nerd Font:Regular:15.0" \
    label.padding_left=0 label.padding_right=0 label.width=0 \
    $ISLAND_BG \
  --add item island.r e \
  --set island.r drawing=off width=dynamic padding_left=0 padding_right=0 \
    icon.drawing=off icon.padding_left=0 icon.padding_right=0 icon.width=0 \
    icon.background.height=4 icon.background.corner_radius=2 icon.background.color=0x00000000 \
    label.padding_left=0 label.padding_right=0 label.width=0 \
    label.background.height=4 label.background.corner_radius=2 label.background.color=0x00000000 \
    $ISLAND_BG >> "$ISLAND_LOG" 2>&1

sketchybar --add bracket island_top island.l island.r \
  --set island_top background.drawing=on background.color=0xff000000 \
    background.height=16 background.y_offset=$(( 11 * Y_ZNAK )) background.corner_radius=0 >> "$ISLAND_LOG" 2>&1

# hidden items: the one that reacts to everything, and the music check every 3 s
sketchybar --add item island left \
  --set island drawing=off updates=on update_freq=0 script="$PLUGIN_DIR/island.sh" \
  --subscribe island volume_change brightness_change power_source_change \
    island_cmd island_media island_pomodoro \
  --add item island_media left \
  --set island_media drawing=off updates=on update_freq=3 script="$PLUGIN_DIR/island_media.sh" >> "$ISLAND_LOG" 2>&1

# TEMP test remote (plugins/island_test.sh) - delete when the island is done
sketchybar --add item island_test left \
  --set island_test drawing=off updates=on update_freq=1 script="$PLUGIN_DIR/island_test.sh" >> "$ISLAND_LOG" 2>&1
