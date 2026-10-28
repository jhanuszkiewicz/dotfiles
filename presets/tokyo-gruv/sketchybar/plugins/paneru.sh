#!/bin/bash
# refreshes workspaces and the window strip at once, from paneru's state
# needs jq (brew install jq)

export PATH=/opt/homebrew/bin:$HOME/.cargo/bin:$PATH
source "$CONFIG_DIR/colors.sh"

stan=$(paneru query state --json 2>/dev/null)
[ -z "$stan" ] && exit 0
# position for ctrl+alt+h/l (scripts/desk-nav), saved here so they don't query paneru
echo "$stan" | "$HOME/.dotfiles/scripts/desk-cache" &

IKONY=0
if [ -f "$CONFIG_DIR/plugins/icon_map.sh" ]; then
  source "$CONFIG_DIR/plugins/icon_map.sh"
  IKONY=1
fi

# all changes collected and sent in one sketchybar call (no flicker)
args=()

# --- workspaces ---
# each of the 5 is a dot: empty = dark, with windows = grey, active = accent pill
# all empty first, then overwritten with what paneru says
for nr in 1 2 3 4 5
do
  ws[$nr]=pusty
done

# only the ones from the current screen / macos space
# line = number, is active, window count (without floating ones)
while read -r nr aktywny ile
do
  [ "$nr" -gt 5 ] && continue
  if [ "$aktywny" = "true" ]; then
    ws[$nr]=aktywny
  elif [ "$ile" -gt 0 ]; then
    ws[$nr]=zajety
  fi
done < <(echo "$stan" | jq -r '
  .active.native_workspace_id as $ws
  | .virtual_workspaces[]
  | select(.native_workspace_id == $ws)
  | "\(.number) \(.active) \([.windows[] | select(.floating | not)] | length)"')

# --- window strip ---
i=0
while IFS=$'\t' read -r apka fokus
do
  i=$((i+1))
  [ $i -gt 8 ] && break

  # kitty shows up as a plain "Terminal" with a >_ icon
  if [ "$apka" = "kitty" ]; then
    apka="Terminal"
  fi

  ikona=""
  if [ $IKONY = 1 ]; then
    __icon_map "$apka"
    ikona="$icon_result"
  fi

  if [ "$fokus" = "true" ]; then
    # focused window: highlighted background + name
    args+=(--set win.$i drawing=on icon="$ikona" icon.color=$BLUE
           label="$apka" label.drawing=on label.color=$FG
           background.drawing=on)
  elif [ $IKONY = 1 ]; then
    # the rest as grey icons only, to keep it short
    args+=(--set win.$i drawing=on icon="$ikona" icon.color=$GREY
           label.drawing=off background.drawing=off)
  else
    args+=(--set win.$i drawing=on label="$apka" label.drawing=on
           label.color=$GREY background.drawing=off)
  fi
done < <(echo "$stan" | jq -r '
  .active.native_workspace_id as $ws
  | .virtual_workspaces[]
  | select(.active and .native_workspace_id == $ws)
  | .windows[]
  | select(.floating | not)
  | "\(.app_name)\t\(.focused)"')

# empty workspace - so the segment doesn't disappear
if [ $i = 0 ]; then
  args+=(--set win.1 drawing=on icon="" label="pusto" label.drawing=on
         label.color=$GREY background.drawing=off)
  i=1
fi

# hide the unused slots
for j in $(seq $((i+1)) 8)
do
  args+=(--set win.$j drawing=off)
done

sketchybar "${args[@]}"

# dots separately, animated - the pill stretches instead of jumping
kropki=()
for nr in 1 2 3 4 5
do
  case "${ws[$nr]}" in
    aktywny) kropki+=(--set space.$nr label.width=22 background.color=$BLUE) ;;
    zajety)  kropki+=(--set space.$nr label.width=8 background.color=$GREY) ;;
    *)       kropki+=(--set space.$nr label.width=8 background.color=$RAMKA) ;;
  esac
done
sketchybar --animate tanh 12 "${kropki[@]}"
