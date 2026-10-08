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
echo "gotowe"
