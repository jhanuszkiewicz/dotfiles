#!/bin/bash
# click on row K of the dropdown: a normal item gets clicked in the app,
# a submenu (or "‹ back") opens in the same dropdown

AX="$HOME/.dotfiles/menu-search/menu-ax"
CACHE="/tmp/sketchybar_menus_$USER"
ROWS="/tmp/sketchybar_menu_rows_$USER"
PLUGINS="$CONFIG_DIR/plugins"

k=$1
n=$(head -1 "$ROWS")
pid=$(head -1 "$CACHE" | cut -f1)
wiersz=$(sed -n "$((k + 1))p" "$ROWS")
rodzaj=${wiersz%%$'\t'*}
sciezka=${wiersz#*$'\t'}

case "$rodzaj" in
  item)
    # dropdown away first - the click may open a dialog in the app
    "$PLUGINS/menu_close.sh"
    "$AX" press "$pid" "$sciezka" 2>/dev/null
    ;;
  sub|up)
    "$PLUGINS/menu_open.sh" "$n" "$sciezka"
    ;;
esac
