#!/bin/sh

# close shortcut search if opened, open if closed

if pgrep -f "ghostty --title=keys" > /dev/null; then
    pkill -f "ghostty --title=keys"
else
    ~/.dotfiles/scripts/popup keys ~/.dotfiles/scripts/keys 80 75 &
fi
