#!/bin/sh

# close launcher if opened, open if closed

if pgrep -f "ghostty --title=launcher" > /dev/null; then
    pkill -f "ghostty --title=launcher"
else
    ~/.dotfiles/scripts/popup launcher ~/.dotfiles/scripts/launcher.sh 50 50 &
fi
