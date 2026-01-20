typeset -U path fpath

SHELL_SESSIONS_DISABLE=1
export CLICOLOR=1

path=(
  $HOME/.local/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
  $path
)
