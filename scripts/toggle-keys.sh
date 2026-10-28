#!/bin/sh

# close shortcut search if opened, open if closed

if pgrep -f "kitty --title=keys" > /dev/null; then
    pkill -f "kitty --title=keys"
else
    ~/.dotfiles/scripts/popup keys ~/.dotfiles/scripts/keys &
fi
