#!/bin/sh

# close anki popup if opened, open if closed

if pgrep -f "kitty --title=anki" > /dev/null; then
    pkill -f "kitty --title=anki"
else
    ~/.dotfiles/scripts/popup anki ~/.dotfiles/scripts/anki &
fi
