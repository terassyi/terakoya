# zplug settings
export ZPLUG_HOME=~/.zplug
source $ZPLUG_HOME/init.zsh

# windows mount path

#plugins
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-autosuggestions"
zplug mafredri/zsh-async, from:github

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi


# Then, source plugins and add commands to $PATH
zplug load

# command alias
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias cl='clear'
alias ..='cd ..'
alias date="gdate"
# alias cat="batcat"
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

PYTHONDONTWRITEBYTECODE=1

# deno settings
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# peco settings
# history
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

# share .zshhistory
setopt inc_append_history
setopt share_history

function peco-history-selection() {
    BUFFER=`history -n 1 | tail -r  | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
}

zle -N peco-history-selection
bindkey '^R' peco-history-selection

# aqua path
export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

eval "$(starship init zsh)"
