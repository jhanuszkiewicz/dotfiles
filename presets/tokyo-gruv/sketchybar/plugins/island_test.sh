#!/bin/bash
# TEMP test remote for tuning the notch island (delete when done)
# runs once a second, reads one word command from ~/.dotfiles/.debug/cmd and
# does ONLY one of the fixed actions below (nothing else from the file is run)

export PATH=/opt/homebrew/bin:$PATH
F="$HOME/.dotfiles/.debug/cmd"
[ -s "$F" ] || exit 0
read -r co arg < "$F"
: > "$F"
W="$CONFIG_DIR/plugins/island.sh"
LOG="$HOME/.dotfiles/.debug/island.log"

case "$co" in
  reload)  sketchybar --reload ;;
  vol)     SENDER=volume_change INFO="${arg:-50}" "$W" >> "$LOG" 2>&1 ;;
  jasn)    SENDER=brightness_change INFO="${arg:-0.6}" "$W" >> "$LOG" 2>&1 ;;
  blad)    SENDER=island_cmd CMD=g++ CODE=1 "$W" >> "$LOG" 2>&1 ;;
  ac)      SENDER=power_source_change INFO=AC "$W" >> "$LOG" 2>&1 ;;
  bat)     SENDER=power_source_change INFO=BATTERY "$W" >> "$LOG" 2>&1 ;;
  muzyka)  SENDER=island_media TITLE="Aruarian Dance" ARTIST="Nujabes" "$W" >> "$LOG" 2>&1 ;;
  pomo)    "$HOME/.dotfiles/scripts/pomodoro" 1 > /dev/null 2>&1 ;;
  stop)    "$HOME/.dotfiles/scripts/pomodoro" stop > /dev/null 2>&1 ;;
  # pictures of ONLY the strip around the notch (top 50 pt, middle of the screen)
  # "foto" = one picture now, "klatki" = 8 pictures every 0.06 s (to see the animation)
  foto)    screencapture -x -R 356,0,800,50 "$HOME/.dotfiles/.debug/foto.png" ;;
  klatki)  for k in 1 2 3 4 5 6 7 8; do
             screencapture -x -R 356,0,800,50 "$HOME/.dotfiles/.debug/klatka$k.png"
             sleep 0.06
           done ;;
esac
