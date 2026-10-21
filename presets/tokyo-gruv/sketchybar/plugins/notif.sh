#!/bin/bash
# unread messages from slack / discord / messenger on the bar, runs every 5 s
# slack and discord: the red badge from the dock (lsappinfo sees it even with the dock hidden)
# messenger has no mac app anymore, so it counts its firefox notifications instead (notif_db.py)
# the latest messages go to a file for the popup (notif_click.sh)

export PATH=/opt/homebrew/bin:$PATH
. "$CONFIG_DIR/colors.sh"

# gruvbox blue (BLUE in colors.sh is the brown accent)
DISCORD=0xff83a598

cache="$HOME/.cache/sketchybar"
mkdir -p "$cache"

# badge text of an app: "3", "•" or nothing
badge() {
  lsappinfo info -only StatusLabel "$1" 2>/dev/null | sed -n 's/.*"label"="\([^"]*\)".*/\1/p'
}

seen=$(cat "$cache/messenger-seen" 2>/dev/null)
[ -z "$seen" ] && seen=0
python3 "$CONFIG_DIR/plugins/notif_db.py" "$seen" > "$cache/notif.tsv" 2>/dev/null

args=()
visible=0
for app in slack discord messenger
do
  case $app in
    slack)
      n=$(badge Slack)
      color=$PURPLE ;;
    discord)
      n=$(badge Discord)
      color=$DISCORD ;;
    messenger)
      # badge only if there's a web app called Messenger, otherwise firefox notifications
      n=$(badge Messenger)
      if [ -z "$n" ]; then
        n=$(grep -c $'^messenger\t' "$cache/notif.tsv")
      fi
      color=$CYAN ;;
  esac

  if [ -z "$n" ] || [ "$n" = "0" ]; then
    args+=(--set notif.$app drawing=off)
  else
    visible=$((visible+1))
    args+=(--set notif.$app drawing=on label="$n" icon.color=$color label.color=$color)
  fi
done

if [ $visible = 0 ]; then
  # nothing new - no separator and no popup either
  args+=(--set sep.n drawing=off --set gap.r0 popup.drawing=off)
else
  args+=(--set sep.n drawing=on)
fi

sketchybar "${args[@]}"
