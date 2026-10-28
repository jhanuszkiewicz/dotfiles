#!/bin/sh

# close launcher if opened, open if closed

if pgrep -f "kitty --title=launcher" > /dev/null; then
    pkill -f "kitty --title=launcher"
else
    ~/.dotfiles/scripts/popup launcher ~/.dotfiles/scripts/launcher.sh &
fi
