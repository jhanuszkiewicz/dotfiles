#!/bin/sh
# zuzycie cpu w % - suma z ps podzielona przez liczbe rdzeni
. "$CONFIG_DIR/colors.sh"

rdzenie=$(sysctl -n hw.ncpu)
proc=$(ps -A -o %cpu= | awk -v r="$rdzenie" '{s+=$1} END {printf "%d", s/r}')

kolor=$FG
if [ "$proc" -ge 80 ]; then
  kolor=$RED
elif [ "$proc" -ge 50 ]; then
  kolor=$ORANGE
fi

sketchybar --set "$NAME" label="${proc}%" label.color=$kolor
