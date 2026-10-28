#!/bin/bash
# app menus of the frontmost app (Finder File Edit View ...) - the macos menu bar
# is hidden under sketchybar, so this is the way to it.
# click = our own dropdown under the title (menu_open.sh)
# » = the menus that didn't fit before the notch, in the menu search (same as alt+m)
#
# senders:
#   front_app_switched / forced / system_woke -> read the menus (menu-ax bar) + lay them out
#   menus_fit (from paneru.sh, the window strip changed) -> only lay them out again
#   mouse.exited.global -> mouse left the bar and the dropdown, close the dropdown
#
# reading the menus needs Accessibility for sketchybar
# (System Settings › Privacy & Security › Accessibility, + /opt/homebrew/bin/sketchybar)
# without it only the app name shows

export PATH=/opt/homebrew/bin:$PATH
source "$CONFIG_DIR/colors.sh"

AX="$HOME/.dotfiles/menu-search/menu-ax"
# what menu-ax bar said: app, notch, screen + every title with its width
CACHE="/tmp/sketchybar_menus_$USER"
LOCK="/tmp/sketchybar_menus_$USER.lock"
SLOTS=12

if [ "$SENDER" = "mouse.exited.global" ]; then
  [ -f "/tmp/sketchybar_menu_open_$USER" ] && "$CONFIG_DIR/plugins/menu_close.sh"
  exit 0
fi

# one menus.sh at a time, otherwise a re-layout with the old app's titles can
# land after the new ones. "try" = give up right away when busy
take_lock() {
  local proby=0
  while ! mkdir "$LOCK" 2>/dev/null
  do
    # older than 5 s = left behind by a run that got killed
    zmiana=$(stat -f %m "$LOCK" 2>/dev/null)
    if [ -n "$zmiana" ] && [ $(( $(date +%s) - zmiana )) -gt 5 ]; then
      rmdir "$LOCK" 2>/dev/null
      continue
    fi
    [ "$1" = "try" ] && return 1
    proby=$((proby + 1))
    [ $proby -gt 60 ] && return 1
    sleep 0.05
  done
  trap 'rmdir "$LOCK" 2>/dev/null' EXIT
  return 0
}

if [ "$SENDER" = "menus_fit" ]; then
  # the menus run that's busy will lay things out anyway
  take_lock try || exit 0
else
  take_lock || exit 0

  out=""
  rc=0
  if [ -x "$AX" ]; then
    out=$("$AX" bar 2>/dev/null)
    rc=$?
    # an app that just launched may not have its menu bar yet - one more try
    # (exit 2 = no permission, no point waiting then)
    if [ $rc != 2 ] && [ "$(printf '%s\n' "$out" | wc -l)" -lt 2 ]; then
      sleep 1
      out=$("$AX" bar 2>/dev/null)
    fi
  fi
  # menu-ax missing or broken - at least the app name from the event
  if [ -z "$out" ]; then
    [ -z "$INFO" ] && exit 0
    out=$(printf '0\t%s\t0\t0' "$INFO")
  fi
  printf '%s\n' "$out" > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"

  # every menu of this app into files in the background, so a click on a title can
  # show its dropdown at once (menu_open.sh). a folder per app - a dump of the
  # previous app that's still running can't mix its files in
  DUMP="/tmp/sketchybar_menu_dump_$USER"
  rm -rf "$DUMP"
  nowy_pid=$(printf '%s\n' "$out" | head -1 | cut -f1)
  if [ $rc = 0 ] && [ "${nowy_pid:-0}" != 0 ]; then
    mkdir -p "$DUMP/$nowy_pid"
    ( nice "$AX" dump "$nowy_pid" "$DUMP/$nowy_pid" > /dev/null 2>&1 & )
  fi

  # a dropdown of the previous app makes no sense anymore
  "$CONFIG_DIR/plugins/menu_close.sh"
fi

[ -f "$CACHE" ] || exit 0
IFS=$'\t' read -r pid app lewo ekran < "$CACHE"

# where the menu segment starts on the bar (it moves when the window strip changes)
x0=$(sketchybar --query gap.m0 | jq -r '.bounding_rects | to_entries[0].value.origin[0] // empty' | cut -d. -f1)
[ -z "$x0" ] && x0=400

# menus end a bit before the notch (no notch = the middle of the screen)
koniec=${lewo:-0}
[ "$koniec" -le 0 ] && koniec=$(( ${ekran:-0} / 2 ))
[ "$koniec" -le 0 ] && koniec=700
miejsce=$(( koniec - x0 - 6 - 14 ))

# each title = its width + 8 + 8 padding. everything fits? no room needed for »
suma=0
while IFS=$'\t' read -r idx title w
do
  [ -z "$idx" ] && continue
  suma=$(( suma + ${w:-70} + 16 ))
done < <(tail -n +2 "$CACHE")
limit=$miejsce
[ $suma -gt $miejsce ] && limit=$(( miejsce - 30 ))

args=()
n=0
used=0
more=0
while IFS=$'\t' read -r idx title w
do
  [ -z "$idx" ] && continue
  szer=$(( ${w:-70} + 16 ))
  if [ $n -ge 1 ] && { [ $(( used + szer )) -gt $limit ] || [ $n -ge $SLOTS ]; }; then
    more=1
    break
  fi
  n=$((n+1))
  used=$(( used + szer ))

  # the first one is the app menu - its title is the app name, brighter
  kolor=$FG2
  [ $n = 1 ] && kolor=$FG
  args+=(--set menu.$n drawing=on label="$title" label.color=$kolor
         click_script="$CONFIG_DIR/plugins/menu_open.sh $n")
done < <(tail -n +2 "$CACHE")

# no menus (no permission, app without a menu bar) - just the name,
# a click opens the menu search instead
if [ $n = 0 ] && [ -n "$app" ]; then
  n=1
  args+=(--set menu.1 drawing=on label="$app" label.color=$FG
         click_script="$HOME/.dotfiles/scripts/toggle-menu.sh")
fi

for j in $(seq $((n+1)) $SLOTS)
do
  args+=(--set menu.$j drawing=off)
done

# a dropdown is open (re-layout while it's open) - its title stays inverted
otwarte=$(cut -d' ' -f1 "/tmp/sketchybar_menu_open_$USER" 2>/dev/null)
if [ -n "$otwarte" ] && [ "$otwarte" -le $n ]; then
  args+=(--set menu.$otwarte label.color=$CRUST)
fi

if [ $more = 1 ]; then
  args+=(--set menu.more drawing=on)
else
  args+=(--set menu.more drawing=off)
fi

sketchybar "${args[@]}"
