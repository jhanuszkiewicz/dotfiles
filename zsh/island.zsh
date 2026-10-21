# notch island: shows failed compile commands (sketchybar, plugins/island.sh)
# add to .zshrc:   source ~/.dotfiles/zsh/island.zsh

autoload -Uz add-zsh-hook

_island_cmd=""

_island_preexec() {
  _island_cmd="$1"
}

_island_precmd() {
  local kod=$?
  local cmd="$_island_cmd"
  _island_cmd=""
  [ -z "$cmd" ] && return
  [ $kod -eq 0 ] && return
  # first word of the command
  local pierwsze=${${(z)cmd}[1]}
  case "$pierwsze" in
    g++|gcc|clang|clang++|c++|cc|make|cmake|ninja|cargo|javac|mvn|gradle)
      sketchybar --trigger island_cmd CMD="$pierwsze" CODE="$kod" &!
      ;;
  esac
}

add-zsh-hook preexec _island_preexec
# first in the list, so $? is still the command's exit code (starship etc. come after)
precmd_functions=(_island_precmd ${precmd_functions:#_island_precmd})
