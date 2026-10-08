#!/bin/bash
# slucha eventow z paneru i mowi sketchybarowi zeby odswiezyl workspace'y i okna

PANERU=/opt/homebrew/bin/paneru
[ -x $PANERU ] || PANERU=$HOME/.cargo/bin/paneru

while true
do
  $PANERU subscribe --json 2>/dev/null | while read -r linia
  do
    case "$linia" in
      *virtual_workspace_changed*|*windows_changed*|*window_focused*)
        sketchybar --trigger paneru_change
        ;;
    esac
  done
  # paneru nie chodzi albo sie zrestartowal - czekam i probuje dalej
  sleep 2
done
