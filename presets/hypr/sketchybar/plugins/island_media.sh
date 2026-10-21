#!/bin/bash
# every 3 s checks what's playing (media-control from homebrew) and on a new song
# sends island_media - on macos 26 the built-in media_change doesn't work anymore
# brew install media-control  (without it this script does nothing)

export PATH=/opt/homebrew/bin:$PATH
command -v media-control > /dev/null || exit 0

dane=$(media-control get 2>/dev/null)
[ -z "$dane" ] && exit 0
[ "$dane" = "null" ] && exit 0

tytul=$(echo "$dane" | jq -r '.title // empty')
artysta=$(echo "$dane" | jq -r '.artist // empty')
gra=$(echo "$dane" | jq -r '.playing // false')

plik="/tmp/sketchybar_media_$USER"
ostatni=$(cat "$plik" 2>/dev/null)

if [ "$gra" = "true" ] && [ -n "$tytul" ] && [ "$tytul" != "$ostatni" ]; then
  echo "$tytul" > "$plik"
  sketchybar --trigger island_media TITLE="$tytul" ARTIST="${artysta:-now playing}"
fi
