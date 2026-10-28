#!/bin/sh
# cpu click - btop in a popup, second click closes it (same idea as toggle-ctl.sh)

if pgrep -f "kitty --title=btop" > /dev/null; then
    pkill -f "kitty --title=btop"
else
    ~/.dotfiles/scripts/popup btop /opt/homebrew/bin/btop &
fi
