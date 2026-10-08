#!/bin/bash
# colors the workspace names: active = bright, has windows = normal, empty = dim
# needs jq (brew install jq)

export PATH=/opt/homebrew/bin:$HOME/.cargo/bin:$PATH
source "$CONFIG_DIR/colors.sh"

state=$(paneru query state --json 2>/dev/null)
[ -z "$state" ] && exit 0

args=()

while read -r nr active count
do
  [ "$nr" -gt 5 ] && continue
  if [ "$active" = "true" ]; then
    col=$FG_HI
  elif [ "$count" -gt 0 ]; then
    col=$FG
  else
    col=$DIM
  fi
  args+=(--set space.$nr icon.color=$col label.color=$col)
done < <(echo "$state" | jq -r '
  .active.native_workspace_id as $ws
  | .virtual_workspaces[]
  | select(.native_workspace_id == $ws)
  | "\(.number) \(.active) \([.windows[] | select(.floating | not)] | length)"')

sketchybar "${args[@]}"
