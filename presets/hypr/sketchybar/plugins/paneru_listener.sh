#!/bin/bash
# listens to paneru events and tells sketchybar to refresh workspaces and windows
#
# debounced: when you switch windows fast, paneru sends a burst of events.
# refreshing on every one of them means a "paneru query state" for each, right
# while paneru is animating, and that makes the animation stutter.
# so every event restarts a short timer and the bar refreshes once things calm down.

PANERU=/opt/homebrew/bin/paneru
[ -x $PANERU ] || PANERU=$HOME/.cargo/bin/paneru

# how long it has to be quiet before the bar refreshes (seconds)
WAIT=0.15

while true
do
  timer=""
  $PANERU subscribe --json 2>/dev/null | while read -r line
  do
    case "$line" in
      *virtual_workspace_changed*|*windows_changed*|*window_focused*|*display_changed*)
        if [ -n "$timer" ]; then
          kill "$timer" 2>/dev/null
        fi
        ( sleep $WAIT; sketchybar --trigger paneru_change ) &
        timer=$!
        ;;
    esac
  done
  # paneru isn't running or restarted - wait and try again
  sleep 2
done
