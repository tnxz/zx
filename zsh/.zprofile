typeset -U path fpath

SHELL_SESSIONS_DISABLE=1
export CLICOLOR=1

path=(
  $HOME/.local/share/mise/shims
  $HOME/.local/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
  $path
)

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
