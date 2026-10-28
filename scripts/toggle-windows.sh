#!/bin/sh

# close the window list if opened, open if closed

# TEMP debug (delete later)
echo "=== toggle $(date)" >> ~/.dotfiles/.debug/windows.log

if pgrep -f "kitty --title=windows" > /dev/null; then
    pkill -f "kitty --title=windows"
else
    ~/.dotfiles/scripts/popup windows ~/.dotfiles/scripts/windows &
fi
