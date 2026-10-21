#!/bin/bash
# cpu - every 2 s a new point on the graph (0..1) + icon color
# grey normally, yellow from 50%, red from 80%
# height = square root of the load, otherwise 5-10% is an almost flat line

. "$CONFIG_DIR/colors.sh"

rdzenie=$(sysctl -n hw.ncpu)
proc=$(ps -A -o %cpu= | awk -v r="$rdzenie" '{s+=$1} END {printf "%d", s/r}')
if [ "$proc" -gt 100 ]; then
  proc=100
fi

kolor=$GREY
tkolor=$FG2
if [ "$proc" -ge 80 ]; then
  kolor=$RED
  tkolor=$RED
elif [ "$proc" -ge 50 ]; then
  kolor=$YELLOW
  tkolor=$YELLOW
fi

wart=$(awk -v p="$proc" 'BEGIN {printf "%.2f", sqrt(p/100)}')

sketchybar --push "$NAME" "$wart" \
  --set "$NAME" graph.color=$kolor graph.fill_color=0x33${kolor:4} \
  --set cpu_icon icon.color=$kolor label="${proc}%" label.color=$tkolor
