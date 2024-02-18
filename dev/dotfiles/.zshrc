# lang
# export LANG=en_US

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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# GoLang
export GOPATH=${HOME}/go
export PATH=/usr/local/go/bin:${GOPATH}/bin:${PATH}

# peco settings
# history
HISTFILE=$HOME/.zsh-history
HISTSIZE=100000
SAVEHIST=100000

# share .zshhistory
setopt inc_append_history
setopt share_history

function peco-history-selection() {
    BUFFER=`history -n 1 | tac  | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
}

zle -N peco-history-selection
bindkey '^R' peco-history-selection

# aqua path
export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

eval "$(starship init zsh)"

# vagrant settings
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
# export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH=/mnt/c/vagrant
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="/mnt/c/Users/terassyi"

export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"

# deno
export DENO_INSTALL="/home/terassyi/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

source /home/terassyi/.config/broot/launcher/bash/br

# gh
eval "$(gh completion -s zsh)"

# enter ns
function in_ns() {
	pid=$(docker inspect $1 --format '{{.State.Pid}}')
	sudo nsenter --target $pid --net ${@:2}
}
