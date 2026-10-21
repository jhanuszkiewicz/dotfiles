#!/bin/bash
# click on a slack / discord / messenger icon on the bar
#   left  = popup with the latest messages (click again to close)
#   right = open the app right away
# "notif_click.sh open APP" is what a popup row runs: open the app and close the popup
# the popup hangs on gap.r0 (left end of the right segment), leaving the bar closes it

export PATH=/opt/homebrew/bin:$PATH
. "$CONFIG_DIR/colors.sh"

DISCORD=0xff83a598
cache="$HOME/.cache/sketchybar"
anchor=gap.r0

open_app() {
  case $1 in
    slack) open -a Slack ;;
    discord) open -a Discord ;;
    messenger)
      # from now on the older messenger notifications don't count
      date +%s > "$cache/messenger-seen"
      if [ -d /Applications/Messenger.app ] || [ -d "$HOME/Applications/Messenger.app" ]; then
        open -a Messenger
      else
        open https://www.messenger.com
      fi ;;
  esac
}

close_popup() {
  sketchybar --set $anchor popup.drawing=off
}

if [ "$1" = "open" ]; then
  close_popup
  open_app "$2"
  sketchybar --trigger notif_update
  exit 0
fi

if [ "$SENDER" = "mouse.exited.global" ]; then
  close_popup
  exit 0
fi

# from here on only clicks on the bar icons
case "$NAME" in
  notif.*) app=${NAME#notif.} ;;
  *) exit 0 ;;
esac

if [ "$BUTTON" = "right" ]; then
  close_popup
  open_app $app
  exit 0
fi

# already open - close it
if [ "$(sketchybar --query $anchor | jq -r '.popup.drawing')" = "on" ]; then
  close_popup
  exit 0
fi

if [ -f "$CONFIG_DIR/plugins/icon_map.sh" ]; then
  app_font="sketchybar-app-font:Regular:14.0"
else
  app_font="JetBrainsMono Nerd Font:Regular:15.0"
fi
text_font="JetBrainsMono Nerd Font:Medium:13.0"

# rows are built from scratch every time
sketchybar --remove '/nrow\..*/' 2>/dev/null

args=()
i=0
for a in slack discord messenger
do
  info=$(sketchybar --query notif.$a)
  [ "$(echo "$info" | jq -r '.geometry.drawing')" = "on" ] || continue
  count=$(echo "$info" | jq -r '.label.value')
  icon=$(echo "$info" | jq -r '.icon.value')
  case $a in
    slack) color=$PURPLE ;;
    discord) color=$DISCORD ;;
    messenger) color=$CYAN ;;
  esac

  # header: icon, name, count
  i=$((i+1))
  args+=(--add item nrow.$i popup.$anchor
         --set nrow.$i icon="$icon" icon.font="$app_font" icon.color=$color
           label="$a · $count" label.color=$color
           padding_left=10 padding_right=10
           click_script="$CONFIG_DIR/plugins/notif_click.sh open $a")

  # up to 3 latest messages of this app
  shown=0
  while IFS=$'\t' read -r row_app who text
  do
    [ "$row_app" = "$a" ] || continue
    shown=$((shown+1))
    [ $shown -gt 3 ] && break
    i=$((i+1))
    args+=(--add item nrow.$i popup.$anchor
           --set nrow.$i icon="$who" icon.font="$text_font" icon.color=$YELLOW icon.width=150
             label="$text" label.color=$FG2
             padding_left=26 padding_right=10
             click_script="$CONFIG_DIR/plugins/notif_click.sh open $a")
  done < "$cache/notif.tsv"
done

if grep -q '^#nodb' "$cache/notif.tsv" 2>/dev/null; then
  i=$((i+1))
  args+=(--add item nrow.$i popup.$anchor
         --set nrow.$i icon.drawing=off label="no previews - sketchybar needs Full Disk Access"
           label.color=$GREY padding_left=10 padding_right=10)
fi

[ $i = 0 ] && exit 0
sketchybar "${args[@]}" --set $anchor popup.drawing=on
