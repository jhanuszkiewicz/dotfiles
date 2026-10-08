
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="$HOME/.local/bin:$PATH"

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)

alias ls="eza --icons=auto"
alias ll="eza -la --icons=auto --git"
alias lt="eza --tree --level=2 --icons=auto"

export PATH="$HOME/.dotfiles/scripts:$PATH"

export FZF_DEFAULT_OPTS_FILE="$HOME/.dotfiles/fzf/colors"
