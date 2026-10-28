#!/bin/bash
# refreshes workspaces and the window strip at once, from paneru's state
# needs jq (brew install jq)
#
# only one refresh runs at a time. before there could be a few at once (listener,
# wake, reload) and the one that finished last won - sometimes with older state,
# so the strip got stuck on windows that were already gone.
# now a refresh that comes in while another one is running just leaves a note,
# and the running one does one more round at the end.

export PATH=/opt/homebrew/bin:$HOME/.cargo/bin:$PATH
source "$CONFIG_DIR/colors.sh"

LOCK="/tmp/sketchybar_paneru_$USER.lock"
AGAIN="/tmp/sketchybar_paneru_$USER.again"

IKONY=0
if [ -f "$CONFIG_DIR/plugins/icon_map.sh" ]; then
  source "$CONFIG_DIR/plugins/icon_map.sh"
  IKONY=1
fi

refresh() {
  local stan
  stan=$(paneru query state --json 2>/dev/null)
  [ -z "$stan" ] && return
  # position for ctrl+alt+h/l (scripts/desk-nav), saved here so they don't query paneru
  echo "$stan" | "$HOME/.dotfiles/scripts/desk-cache" &

  # all changes collected and sent in one sketchybar call (no flicker)
  local args=()
  local ws=()

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
    [ -z "$nr" ] && continue
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
  # icons only - the name of the focused app is in the menu segment now
  local i=0
  while IFS=$'\t' read -r apka fokus
  do
    [ -z "$apka" ] && continue
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

    if [ $IKONY = 0 ]; then
      # no app font - names instead of icons
      kolor=$GREY
      [ "$fokus" = "true" ] && kolor=$FG
      args+=(--set win.$i drawing=on label="$apka" label.drawing=on
             label.color=$kolor background.drawing=off)
    elif [ "$fokus" = "true" ]; then
      # focused window: accent icon on a highlighted background
      args+=(--set win.$i drawing=on icon="$ikona" icon.color=$BLUE
             label.drawing=off background.drawing=on)
    else
      args+=(--set win.$i drawing=on icon="$ikona" icon.color=$GREY
             label.drawing=off background.drawing=off)
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
  # the strip may be wider or narrower now - menus.sh fits the menus before the notch again
  sketchybar --trigger menus_fit

  # dots separately, animated - the pill stretches instead of jumping
  local kropki=()
  for nr in 1 2 3 4 5
  do
    case "${ws[$nr]}" in
      aktywny) kropki+=(--set space.$nr label.width=22 background.color=$BLUE) ;;
      zajety)  kropki+=(--set space.$nr label.width=8 background.color=$GREY) ;;
      *)       kropki+=(--set space.$nr label.width=8 background.color=$RAMKA) ;;
    esac
  done
  sketchybar --animate tanh 12 "${kropki[@]}"
}

# a lock left behind by a refresh that got killed halfway - older than 5 s = stale
lock_is_stale() {
  local zmiana
  zmiana=$(stat -f %m "$LOCK" 2>/dev/null) || return 1
  [ $(( $(date +%s) - zmiana )) -gt 5 ]
}

while true
do
  if ! mkdir "$LOCK" 2>/dev/null; then
    if lock_is_stale; then
      touch "$LOCK"
    else
      # someone is refreshing right now - ask for one more round and leave
      touch "$AGAIN"
      exit 0
    fi
  fi
  trap 'rmdir "$LOCK" 2>/dev/null' EXIT

  while true
  do
    rm -f "$AGAIN"
    refresh
    [ -f "$AGAIN" ] || break
  done

  rmdir "$LOCK" 2>/dev/null
  trap - EXIT
  # a note that came in right before the lock was gone - one more go
  [ -f "$AGAIN" ] || break
done
