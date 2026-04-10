if [ -x "$HOME/opt/anaconda3/bin/conda" ]; then
  __conda_setup="$("$HOME/opt/anaconda3/bin/conda" shell.zsh hook 2> /dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  elif [ -f "$HOME/opt/anaconda3/etc/profile.d/conda.sh" ]; then
    . "$HOME/opt/anaconda3/etc/profile.d/conda.sh"
  fi
  unset __conda_setup
fi
