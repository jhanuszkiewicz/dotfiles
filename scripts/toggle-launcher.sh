#!/bin/sh

# close launcher if opened, open if closed

if pgrep -f "alacritty --title launcher" > /dev/null; then
    pkill -f "alacritty --title launcher"
else
    /Applications/Alacritty.app/Contents/MacOS/alacritty --title launcher \
        -o "window.dimensions={columns=70, lines=20}" \
        -o "window.position={x=950, y=450}" \
        -e ~/.dotfiles/scripts/launcher.sh &
fi
