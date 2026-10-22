#!/bin/bash
# linkuje configi z dotfiles do ~/.config

DOT=~/.dotfiles

for p in paneru sketchybar borders ghostty btop bat nvim tmux skhd karabiner git
do
  if [ -e ~/.config/$p ] && [ ! -L ~/.config/$p ]; then
    echo "pomijam $p - w ~/.config jest prawdziwy folder, przenies go recznie"
  else
    ln -sfn $DOT/$p ~/.config/$p
    echo "zlinkowano $p"
  fi
done

ln -sf $DOT/starship/starship.toml ~/.config/starship.toml
ln -sf $DOT/zsh/.zshrc ~/.zshrc
# launchd doesn't like symlinked plists, so copy them
mkdir -p ~/Library/LaunchAgents
cp $DOT/launchd/*.plist ~/Library/LaunchAgents/
# terminal tools that aren't configs
# clanki - anki reviews in the terminal (scripts/anki, alt+shift+a)
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
command -v uv > /dev/null || brew install uv
command -v clanki > /dev/null || uv tool install clanki

echo "gotowe"
