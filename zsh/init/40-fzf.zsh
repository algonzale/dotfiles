if [[ -o interactive ]] && [ -t 0 ] && [ -f "$HOME/.fzf.zsh" ]; then
  source "$HOME/.fzf.zsh"
fi
