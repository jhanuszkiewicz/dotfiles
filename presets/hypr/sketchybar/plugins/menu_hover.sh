#!/bin/bash
# dropdown rows: the row under the mouse in inverted colors (tmux menu style).
#   on enter every row is reset first, so two rows can't stay lit when the
#   enter/exit scripts of neighbouring rows finish in the wrong order
# titles: no hover look (like macos). with a dropdown open, moving onto
#   another title opens that one

source "$CONFIG_DIR/colors.sh"
otwarte=$(cut -d' ' -f1 "/tmp/sketchybar_menu_open_$USER" 2>/dev/null)

case "$NAME" in
  mpop.c.*)
    if [ "$SENDER" = "mouse.entered" ]; then
      sketchybar --set '/mpop\.c\./' background.color=0x00000000 label.color=$FG icon.color=$BLUE \
        --set "$NAME" background.color=$BLUE label.color=$CRUST icon.color=$CRUST
    elif [ "$SENDER" = "mouse.exited" ]; then
      sketchybar --set "$NAME" background.color=0x00000000 label.color=$FG icon.color=$BLUE
    fi
    ;;
  menu.[0-9]*)
    if [ "$SENDER" = "mouse.entered" ] && [ -n "$otwarte" ] && [ "$otwarte" != "${NAME#menu.}" ]; then
      "$CONFIG_DIR/plugins/menu_open.sh" "${NAME#menu.}"
    fi
    ;;
esac
