#!/bin/bash
# odswieza naraz workspace'y i pasek okien na podstawie stanu z paneru
# potrzebuje jq (brew install jq)

export PATH=/opt/homebrew/bin:$HOME/.cargo/bin:$PATH
source "$CONFIG_DIR/colors.sh"

stan=$(paneru query state --json 2>/dev/null)
[ -z "$stan" ] && exit 0

IKONY=0
if [ -f "$CONFIG_DIR/plugins/icon_map.sh" ]; then
  source "$CONFIG_DIR/plugins/icon_map.sh"
  IKONY=1
fi

# wszystkie zmiany zbieram i wysylam jednym wywolaniem sketchybar (bez migania)
args=()

# --- workspace'y ---
# biore tylko te z aktualnego ekranu/space'a macosa
# linijka = numer, czy aktywny, ile okien (bez plywajacych)
while read -r nr aktywny ile
do
  [ "$nr" -gt 5 ] && continue
  if [ "$aktywny" = "true" ]; then
    args+=(--set space.$nr drawing=on background.drawing=on icon.color=$BG)
  elif [ "$ile" -gt 0 ]; then
    args+=(--set space.$nr drawing=on background.drawing=off icon.color=$FG2)
  else
    args+=(--set space.$nr drawing=off)
  fi
done < <(echo "$stan" | jq -r '
  .active.native_workspace_id as $ws
  | .virtual_workspaces[]
  | select(.native_workspace_id == $ws)
  | "\(.number) \(.active) \([.windows[] | select(.floating | not)] | length)"')

# --- pasek okien ---
i=0
while IFS=$'\t' read -r apka fokus
do
  i=$((i+1))
  [ $i -gt 8 ] && break

  ikona=""
  if [ $IKONY = 1 ]; then
    __icon_map "$apka"
    ikona="$icon_result"
  fi

  if [ "$fokus" = "true" ]; then
    # aktywne okno: podswietlone tlo + nazwa
    args+=(--set win.$i drawing=on icon="$ikona" icon.color=$BLUE
           label="$apka" label.drawing=on label.color=$FG
           background.drawing=on)
  elif [ $IKONY = 1 ]; then
    # reszta jako same szare ikonki zeby bylo krotko
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

# pusty workspace - zeby pigulka nie zniknela
if [ $i = 0 ]; then
  args+=(--set win.1 drawing=on icon="" label="pusto" label.drawing=on
         label.color=$GREY background.drawing=off)
  i=1
fi

# chowam nieuzywane sloty
for j in $(seq $((i+1)) 8)
do
  args+=(--set win.$j drawing=off)
done

sketchybar "${args[@]}"
