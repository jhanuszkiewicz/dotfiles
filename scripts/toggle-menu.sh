#!/bin/sh
# alt+m: close the menu search if it's open, open it if closed
# the frontmost app gets saved first - once the popup is up, kitty is the frontmost one

if pgrep -f "kitty --title=menu" > /dev/null; then
    pkill -f "kitty --title=menu"
else
    ~/.dotfiles/menu-search/menu-ax front > "/tmp/menu_search_target_$USER"
    ~/.dotfiles/scripts/popup menu ~/.dotfiles/scripts/menu-search &
fi
