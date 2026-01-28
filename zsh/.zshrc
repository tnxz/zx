typeset -U fpath FPATH

fpath+=(/opt/homebrew/share/zsh/site-functions)

print_osc7() {
  if [ "$ZSH_SUBSHELL" -eq 0 ]; then
    printf "\033]7;file://$PWD\033\\"
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook -Uz chpwd print_osc7
print_osc7

setopt APPEND_HISTORY SHARE_HISTORY EXTENDED_HISTORY HIST_FCNTL_LOCK HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_SPACE INTERACTIVE_COMMENTS HIST_REDUCE_BLANKS INC_APPEND_HISTORY

HISTORY_IGNORE="(l|c|ll|ls|cd|pwd|exit|z|z -|z ..)"
HISTSIZE=10000000
SAVEHIST=10000000

zstyle ':completion:*' menu select
zmodload zsh/complist
autoload -Uz compinit
compinit
_comp_options+=(globdots)

KEYTIMEOUT=1

bindkey -v

function zle-keymap-select zle-line-init {
  case $KEYMAP in
    vicmd) print -n '\e[2 q';;
    viins|main) print -n '\e[6 q';;
  esac
}
zle -N zle-line-init
zle -N zle-keymap-select

function preexec { print -n '\e[2 q' }

function vi-yank-pbcopy { zle vi-yank; echo "$CUTBUFFER" | pbcopy }
zle -N vi-yank-pbcopy
bindkey -M vicmd 'y' vi-yank-pbcopy

function vi-put-after-pbcopy { CUTBUFFER=$(pbpaste); zle vi-put-after }
zle -N vi-put-after-pbcopy
bindkey -M vicmd 'p' vi-put-after-pbcopy

function vi-put-before-pbcopy { CUTBUFFER=$(pbpaste); zle vi-put-before }
zle -N vi-put-before-pbcopy
bindkey -M vicmd 'P' vi-put-before-pbcopy

bindkey '^[[Z' reverse-menu-complete
bindkey -v '^?' backward-delete-char
bindkey -M vicmd -r :
bindkey -M vicmd "^U" vi-change-whole-line
bindkey -M vicmd "^E" vi-add-eol
bindkey -M vicmd "^A" vi-insert-bol
bindkey -M vicmd "^K" vi-change-eol
bindkey -M viins "^A" beginning-of-line
bindkey -M viins "^E" end-of-line
bindkey -M viins "^K" kill-line
bindkey -M viins "^L" clear-screen
bindkey -M viins "^W" backward-kill-word
bindkey -M viins "^Y" yank
bindkey -M viins "^U" kill-whole-line
bindkey -M viins "^P" history-search-backward
bindkey -M viins "^N" history-search-forward
bindkey -M menuselect "\e" send-break

alias ll="ls -ASlh"
alias c="printf '\e[H\e[3J'"
alias l="ls -AS"

if (( $+commands[fzf] )); then
  FZF_DEFAULT_OPTS="--bind 'tab:down,shift-tab:up' --cycle"
  source <(fzf --zsh)
  bindkey -M vicmd '/' fzf-history-widget
  bindkey -M vicmd '?' fzf-history-widget
fi

if (( $+commands[mise] )); then
  eval "$(mise completion zsh)"
fi

if (( $+commands[nvim] )); then
  export {EDITOR,VISUAL}="nvim"
  alias vimdiff="nvim -d"
  alias {vi,vim}="nvim"
fi

if (( $+commands[tree] )); then
  alias t="tree -al -I '.git|.venv'"
fi

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

prompt="%m %1~ # "
