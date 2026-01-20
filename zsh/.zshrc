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

setopt interactivecomments appendhistory sharehistory incappendhistory histignorealldups

HISTSIZE=10000000
SAVEHIST=10000000

zstyle ':completion:*' menu select
zmodload zsh/complist
autoload -Uz compinit
compinit
_comp_options+=(globdots)

bindkey -v
export KEYTIMEOUT=1

function zle-keymap-select zle-line-init {
  case $KEYMAP in
    vicmd) print -n '\e[2 q';;
    viins|main) print -n '\e[6 q';;
  esac
}
zle -N zle-line-init
zle -N zle-keymap-select

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

alias ll="ls -AS"
alias c="printf '\e[H\e[3J'"
alias l="ls -AS"

if (( $+commands[fzf] )); then
  source <(fzf --zsh)
  bindkey -M vicmd '/' fzf-history-widget
  bindkey -M vicmd '?' fzf-history-widget
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
