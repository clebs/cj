# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_SILENT

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Key bindings
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Aliases
alias g='git'
alias gw='git worktree'
alias gss='git status --short'
alias glo='git log --oneline --decorate'
alias agent='claude --dangerously-skip-permissions'

# Prompt — show container name
PROMPT="%F{cyan}[jail-${JAIL_PROJECT:-?}]%f %F{blue}%~%f %# "
