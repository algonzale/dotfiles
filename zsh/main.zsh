export ZSH_CONFIG_DIR="${ZSH_CONFIG_DIR:-$HOME/dotfiles/zsh}"

typeset -U path PATH

[ -r "$ZSH_CONFIG_DIR/path.zsh" ] && source "$ZSH_CONFIG_DIR/path.zsh"
[ -r "$ZSH_CONFIG_DIR/env.zsh" ] && source "$ZSH_CONFIG_DIR/env.zsh"

for file in "$ZSH_CONFIG_DIR"/init/*.zsh(N); do
  [ -r "$file" ] && source "$file"
done

for file in "$ZSH_CONFIG_DIR"/aliases/*.zsh(N); do
  [ -r "$file" ] && source "$file"
done

for file in "$ZSH_CONFIG_DIR"/functions/*.zsh(N); do
  [ -r "$file" ] && source "$file"
done

for file in "$ZSH_CONFIG_DIR"/local/*.zsh(N); do
  [ -r "$file" ] && source "$file"
done

[ -r "$ZSH_CONFIG_DIR/functions/project_selectors.zsh" ] && source "$ZSH_CONFIG_DIR/functions/project_selectors.zsh"
