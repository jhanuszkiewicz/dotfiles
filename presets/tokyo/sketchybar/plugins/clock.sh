#!/bin/sh
# date in a dim item, time in a bright one: "fri 09.10" + "16:32"

dzien=$(LC_ALL=C date '+%a' | tr 'A-Z' 'a-z')
sketchybar --set date label="$dzien $(date '+%d.%m')" \
  --set "$NAME" label="$(date '+%H:%M')"
