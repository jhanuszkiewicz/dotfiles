#!/bin/sh

# close ctl if opened, open if closed
# toggle-ctl.sh [section] -> opens straight in that section (wifi, bt, audio...)

if pgrep -f "ghostty --title=ctl" > /dev/null; then
    pkill -f "ghostty --title=ctl"
else
    POPUP_W=50
    POPUP_H=50
    . ~/.dotfiles/ctl/config

    mkdir -p ~/.cache
    [ -n "$1" ] && echo "$1" > ~/.cache/ctl-start
    ~/.dotfiles/scripts/popup ctl ~/.dotfiles/scripts/ctl $POPUP_W $POPUP_H &
fi
