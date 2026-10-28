#!/bin/bash
# our own dropdown under menu title N, tmux-menu style: square box, crust background,
# shortcuts as words, the row under the mouse in inverted colors
#   menu_open.sh N           -> menu N (click on the title)
#   menu_open.sh N "a › b"   -> a submenu inside it (menu_pick.sh)
#
# made to feel instant:
#   1. the title turns pink right away, before anything else
#   2. the rows come from the file menus.sh dumped in the background after the app
#      switch (menu-ax dump), so nothing has to ask the app on the click
#   3. then the app is asked anyway, and the dropdown is redrawn only if something
#      changed in the meantime (a checkmark, a greyed out item)
# no file yet (submenu, or the dump isn't done) = ask the app right away like before

source "$CONFIG_DIR/colors.sh"

AX="$HOME/.dotfiles/menu-search/menu-ax"
CACHE="/tmp/sketchybar_menus_$USER"
DUMP="/tmp/sketchybar_menu_dump_$USER"
ROWS="/tmp/sketchybar_menu_rows_$USER"
OPEN="/tmp/sketchybar_menu_open_$USER"
PLUGINS="$CONFIG_DIR/plugins"
F="Departure Mono:Regular:11.0"

n=$1
sciezka=$2

# cache = menus.sh's: first line "pid name ...", then one title per line in bar order
pid=$(head -1 "$CACHE" 2>/dev/null | cut -f1)
top=$(awk -F'\t' -v n="$n" 'NR == n + 1 { print $2 }' "$CACHE" 2>/dev/null)
[ -z "$pid" ] || [ -z "$top" ] && exit 0

# click on the title of the menu that's open = close it, like in macos
if [ -z "$sciezka" ] && [ "$(cut -d' ' -f1 "$OPEN" 2>/dev/null)" = "$n" ]; then
  "$PLUGINS/menu_close.sh"
  exit 0
fi
[ -z "$sciezka" ] && sciezka=$top

# "<menu> <this run>" - when the mouse slides over a few titles quickly, a few of these
# run at once. only the newest one gets to draw, the older ones see it and quit
echo "$n $$" > "$OPEN"
wciaz_moje() {
  [ "$(cat "$OPEN" 2>/dev/null)" = "$n $$" ]
}

# 1. every title back to normal, this one pink with dark text - right away
# (drawing=off has to come after background.color - setting a color turns the background on)
sketchybar --set '/menu\.[0-9][0-9]*/' popup.drawing=off \
    background.color=$BG2 background.height=24 background.corner_radius=6 label.color=$FG2 \
    background.drawing=off \
  --set menu.1 label.color=$FG \
  --set menu.$n background.color=$BLUE background.height=38 background.corner_radius=0 \
    label.color=$CRUST background.drawing=on

# draws the rows of $1 (menu-ax items output) as the dropdown of title n
rysuj() {
  local out=$1
  # first line "W <width of the widest row>", rows after it
  local szer
  szer=$(printf '%s\n' "$out" | head -1 | cut -f2)
  [ -z "$out" ] || [ -z "$szer" ] && return 1

  # a fixed label.width is the whole label - sketchybar doesn't add label.padding_right
  # to it, so the right margin (12) goes into the width, plus 4 in case the measure is a bit off
  szer=$(( szer + 16 ))

  echo "$n" > "$ROWS"
  local args=(--remove '/mpop\..*/')

  # a bit of space above the first row
  args+=(--add item mpop.0 popup.menu.$n
         --set mpop.0 icon.drawing=off label=" " label.font="Departure Mono:Regular:2.0"
           label.width=1 background.drawing=on background.color=0x00000000 background.height=4)

  local k=0
  local rodzaj znak tekst sciezka_el ikona nazwa
  while IFS=$'\t' read -r rodzaj znak tekst sciezka_el
  do
    [ -z "$rodzaj" ] && continue
    [ "$rodzaj" = "W" ] && continue
    k=$((k+1))
    printf '%s\t%s\n' "$rodzaj" "$sciezka_el" >> "$ROWS"

    ikona=" "
    [ "$znak" = "1" ] && ikona="󰄬"

    # clickable rows are mpop.c.K (hover resets all of them at once), the rest mpop.K
    nazwa=mpop.$k
    case "$rodzaj" in
      item|sub|up) nazwa=mpop.c.$k ;;
    esac

    # every row exactly as wide as the widest one, so the hover bar spans the box.
    # the background is always drawn (transparent) - that's what gives the row its height
    args+=(--add item $nazwa popup.menu.$n
           --set $nazwa padding_left=0 padding_right=0
             icon="$ikona" icon.font="JetBrainsMono Nerd Font:Regular:11.0"
             icon.width=16 icon.align=center icon.padding_left=6 icon.padding_right=6
             icon.color=$BLUE
             label="$tekst" label.font="$F" label.width=$szer label.align=left
             label.padding_left=0 label.padding_right=0
             background.drawing=on background.color=0x00000000
             background.height=20 background.corner_radius=0)

    case "$rodzaj" in
      item|sub|up)
        args+=(label.color=$FG click_script="$PLUGINS/menu_pick.sh $k"
               script="$PLUGINS/menu_hover.sh"
               --subscribe $nazwa mouse.entered mouse.exited) ;;
      off)
        args+=(label.color=$GREY) ;;
      sep)
        # short row, the line is the label's background
        args+=(label=" " label.font="Departure Mono:Regular:4.0" background.height=9
               label.width=$(( szer - 12 ))
               label.background.drawing=on label.background.color=$RAMKA
               label.background.height=1 label.background.corner_radius=0) ;;
    esac
  done <<< "$out"

  # and a bit below the last one
  args+=(--add item mpop.end popup.menu.$n
         --set mpop.end icon.drawing=off label=" " label.font="Departure Mono:Regular:2.0"
           label.width=1 background.drawing=on background.color=0x00000000 background.height=6)

  args+=(--set menu.$n popup.drawing=on)
  sketchybar "${args[@]}"
}

# 2. rows from the dumped file if there is one, else from the app
plik="$DUMP/$pid/$n"
z_pliku=0
if [ "$sciezka" = "$top" ] && [ -s "$plik" ]; then
  out=$(cat "$plik")
  z_pliku=1
else
  out=$("$AX" items "$pid" "$sciezka" 2>/dev/null)
fi

wciaz_moje || exit 0
if ! rysuj "$out"; then
  "$PLUGINS/menu_close.sh"
  exit 0
fi

# 3. the file may be a bit old - ask the app now, redraw only if something changed
if [ $z_pliku = 1 ]; then
  nowe=$("$AX" items "$pid" "$sciezka" 2>/dev/null)
  if [ -n "$nowe" ] && [ "$nowe" != "$out" ]; then
    printf '%s\n' "$nowe" > "$plik"
    wciaz_moje && rysuj "$nowe"
  fi
fi
