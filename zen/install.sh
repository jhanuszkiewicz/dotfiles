#!/bin/bash
# linkuje configi z dotfiles do profilu zena
# uzycie: ./install.sh            - sam szuka profilu
#         ./install.sh <sciezka>  - jak wiesz gdzie jest (about:support -> Profile Folder)

dot="$HOME/.dotfiles/zen"
profiles="$HOME/Library/Application Support/zen/Profiles"

prof="$1"

# jak nie podales sciezki to szukam profilu w ktorym jest prefs.js
if [ -z "$prof" ]; then
  ile=0
  for p in "$profiles"/*/; do
    if [ -f "$p/prefs.js" ]; then
      prof="${p%/}"
      ile=$((ile + 1))
    fi
  done

  if [ $ile -eq 0 ]; then
    echo "nie znalazlem profilu, odpal zena raz i sprobuj jeszcze raz"
    exit 1
  fi

  if [ $ile -gt 1 ]; then
    echo "jest kilka profili, podaj sciezke recznie:"
    ls -1 "$profiles"
    echo "(wlasciwy znajdziesz w zenie: about:support -> Profile Folder)"
    exit 1
  fi
fi

echo "profil: $prof"

# stare pliki odkladam na bok zamiast kasowac
if [ -e "$prof/chrome" ] && [ ! -L "$prof/chrome" ]; then
  mv "$prof/chrome" "$prof/chrome.bak"
fi
if [ -e "$prof/user.js" ] && [ ! -L "$prof/user.js" ]; then
  mv "$prof/user.js" "$prof/user.js.bak"
fi

ln -sfn "$dot/chrome" "$prof/chrome"
ln -sf "$dot/user.js" "$prof/user.js"

echo "gotowe, zamknij zena (cmd+q) i odpal ponownie"
