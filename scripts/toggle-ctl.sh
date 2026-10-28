#!/bin/sh

# close ctl if opened, open if closed
# toggle-ctl.sh [section] -> opens straight in that section (wifi, bt, audio...)

if pgrep -f "kitty --title=ctl" > /dev/null; then
    pkill -f "kitty --title=ctl"
else
    mkdir -p ~/.cache
    [ -n "$1" ] && echo "$1" > ~/.cache/ctl-start
    ~/.dotfiles/scripts/popup ctl ~/.dotfiles/scripts/ctl &
fi
