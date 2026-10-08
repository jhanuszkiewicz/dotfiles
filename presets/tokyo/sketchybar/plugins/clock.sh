#!/bin/sh
# np. "wed 07.10  15:57" (dzien tygodnia po angielsku, malymi literami)

dzien=$(LC_ALL=C date '+%a' | tr 'A-Z' 'a-z')
sketchybar --set "$NAME" label="$dzien $(date '+%d.%m  %H:%M')"
