#!/bin/sh
# bez tego fzf moze nie byc widoczny w PATH
export PATH="/opt/homebrew/bin:$PATH"

app=$(find /Applications /System/Applications ~/Applications -maxdepth 2 -name '*.app' 2>/dev/null \
  | sed 's|.*/||; s|\.app$||' | sort -u | fzf --prompt="> " --reverse)

[ -n "$app" ] && open -a "$app"
