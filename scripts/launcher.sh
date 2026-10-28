#!/bin/sh
# app launcher (alt+space): pick an app, it opens in a NEW window
# app not running -> starts it, already running -> brings it up and does cmd+n
# (kitty goes through open-term, same thing)
export PATH="/opt/homebrew/bin:$PATH"
# fzf colors from the active preset
export FZF_DEFAULT_OPTS_FILE="$HOME/.dotfiles/fzf/colors"

app=$(find /Applications /System/Applications ~/Applications -maxdepth 2 -name '*.app' 2>/dev/null \
  | sed 's|.*/||; s|\.app$||' | sort -u | fzf --prompt="new > " --reverse)

[ -z "$app" ] && exit 0

if [ "$app" = "kitty" ]; then
  exec "$HOME/.dotfiles/scripts/open-term"
fi

dziala=$(osascript -e "application \"$app\" is running" 2>/dev/null)
if [ "$dziala" = "true" ]; then
  # short delay so the keystroke lands in the app and not in this popup
  osascript -e "tell application \"$app\" to activate" -e 'delay 0.15' \
    -e 'tell application "System Events" to keystroke "n" using command down'
else
  open -a "$app"
fi
