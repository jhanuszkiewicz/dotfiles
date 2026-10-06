#!/bin/bash
# slucha eventow z paneru i mowi sketchybarowi ze zmienil sie workspace

PANERU=/opt/homebrew/bin/paneru
[ -x $PANERU ] || PANERU=$HOME/.cargo/bin/paneru

while true
do
  $PANERU subscribe --json 2>/dev/null | while read -r linia
  do
    case "$linia" in
      *virtual_workspace_changed*)
        nr=$(echo "$linia" | sed -n 's/.*"virtual_workspace_number":\([0-9]*\).*/\1/p')
        sketchybar --trigger paneru_workspace_change FOCUSED_WORKSPACE=$nr
        ;;
    esac
  done
  # paneru nie chodzi albo sie zrestartowal - czekam i probuje dalej
  sleep 2
done
