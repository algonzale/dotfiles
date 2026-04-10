typeset -U path PATH

export GOPATH="${GOPATH:-$HOME/go}"
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

path=(
  /opt/homebrew/bin
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  /Library/Frameworks/Python.framework/Versions/3.9/bin
  /Library/Frameworks/Python.framework/Versions/3.8/bin
  "$HOME/.local/bin"
  "$GOPATH/bin"
  "$PNPM_HOME"
  "$BUN_INSTALL/bin"
  "$HOME/.antigravity/antigravity/bin"
  $path
)

export PATH
