#!/bin/bash
# claude - two stacked bars (5 h window on top, 7 days below) + 5 h reset time,
# from the cache scripts/claude-usage writes
# bars light grey normally, yellow from 70%, red from 90%; the icon takes the
# color of the worse one. no open window = empty top bar and no time
# hover = popup with exact numbers:
#   5h   6%   reset 21:30 · 2h 26m
#   7d   4%   reset wed 21:00

. "$CONFIG_DIR/colors.sh"

case "$SENDER" in
  mouse.entered)
    sketchybar --set claude popup.drawing=on
    exit 0 ;;
  mouse.exited|mouse.exited.global)
    sketchybar --set claude popup.drawing=off
    exit 0 ;;
esac

CACHE="$HOME/.cache/sketchybar/claude-usage"
[ -f "$CACHE" ] || exit 0
read -r PROC RESET TYDZ TRESET POBRANO < "$CACHE"

now=$(date +%s)
[ "$RESET" -le "$now" ] && PROC=0 && RESET=0
[ "$TRESET" -le "$now" ] && TYDZ=0 && TRESET=0

# bar color for a percentage
kolor() {
  if [ "$1" -ge 90 ]; then
    echo $RED
  elif [ "$1" -ge 70 ]; then
    echo $YELLOW
  else
    echo "$2"
  fi
}
k5=$(kolor $PROC $FG2)
k7=$(kolor $TYDZ $GREY)
max=$PROC
[ "$TYDZ" -gt "$max" ] && max=$TYDZ
kikona=$(kolor $max $GREY)

# "2h 26m" / "14m"
zostalo() {
  s=$(( $1 - now ))
  if [ $s -ge 3600 ]; then
    echo "$(( s / 3600 ))h $(( s % 3600 / 60 ))m"
  else
    echo "$(( s / 60 ))m"
  fi
}

if [ "$RESET" -gt 0 ]; then
  czas=$(date -r "$RESET" +%H:%M)
  tkolor=$FG2
  p5="5h  $(printf '%3d' $PROC)%   reset $czas · $(zostalo $RESET)"
else
  czas="--"
  tkolor=$GREY
  p5="5h    0%   no window open"
fi
if [ "$TRESET" -gt 0 ]; then
  p7="7d  $(printf '%3d' $TYDZ)%   reset $(date -r "$TRESET" '+%a %H:%M' | tr '[:upper:]' '[:lower:]')"
else
  p7="7d    0%"
fi

# cache older than 15 min = launchd job is dead or offline, dim everything
if [ $(( now - POBRANO )) -gt 900 ]; then
  k5=$GREY; k7=$GREY; kikona=$GREY; tkolor=$GREY
  p5="$p5   (stale)"
fi

sketchybar --set claude icon.color=$kikona \
  --set claude.5h slider.percentage=$PROC slider.highlight_color=$k5 \
  --set claude.7d slider.percentage=$TYDZ slider.highlight_color=$k7 \
  --set claude.time label="$czas" label.color=$tkolor \
  --set claude.p5h label="$p5" \
  --set claude.p7d label="$p7"
