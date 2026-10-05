
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

# Added by Antigravity IDE
export PATH="/Users/jhan/.antigravity-ide/antigravity-ide/bin:$PATH"

# motyw
export BAT_THEME="tokyonight_night"
export FZF_DEFAULT_OPTS="--color=bg+:#283457,bg:#1a1b26,border:#27a1b9,fg:#c0caf5,fg+:#c0caf5,gutter:#1a1b26,header:#ff9e64,hl:#2ac3de,hl+:#2ac3de,info:#545c7e,marker:#ff007c,pointer:#ff007c,prompt:#2ac3de,spinner:#ff007c"

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)

alias ls="eza --icons=auto"
alias ll="eza -la --icons=auto --git"
alias lt="eza --tree --level=2 --icons=auto"
