#!/bin/sh
# cpu click - btop in a popup, second click closes it (same idea as toggle-ctl.sh)

if pgrep -f "ghostty --title=btop" > /dev/null; then
    pkill -f "ghostty --title=btop"
else
    ~/.dotfiles/scripts/popup btop /opt/homebrew/bin/btop 70 70 &
fi
