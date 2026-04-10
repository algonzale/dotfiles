unalias fns 2>/dev/null
unalias aliases 2>/dev/null

_dotfiles_print_table_line() {
  emulate -L zsh

  local line="$1"
  shift

  local -a widths=("$@")
  local -a columns
  local output=""
  local index

  local IFS=$'\t'
  columns=(${=line})

  for (( index = 1; index <= ${#widths[@]}; index++ )); do
    output+=$(printf "%-*s" "${widths[index]}" "${columns[index]:-}")
    if (( index < ${#widths[@]} )); then
      output+="  "
    fi
  done

  print -r -- "$output"
}

_dotfiles_print_table() {
  emulate -L zsh

  local header="$1"
  shift

  local -a rows=("$header" "$@")
  local -a widths separators columns
  local separator_row=""
  local row
  local index

  for row in "${rows[@]}"; do
    local IFS=$'\t'
    columns=(${=row})
    for (( index = 1; index <= ${#columns[@]}; index++ )); do
      if (( ${#columns[index]} > ${widths[index]:-0} )); then
        widths[index]=${#columns[index]}
      fi
    done
  done

  for (( index = 1; index <= ${#widths[@]}; index++ )); do
    separators+=("$(printf "%*s" "${widths[index]}" "" | tr " " "-")")
    if (( index > 1 )); then
      separator_row+=$'\t'
    fi
    separator_row+="${separators[index]}"
  done

  _dotfiles_print_table_line "$header" "${widths[@]}"
  _dotfiles_print_table_line "$separator_row" "${widths[@]}"

  for row in "$@"; do
    _dotfiles_print_table_line "$row" "${widths[@]}"
  done
}

_dotfiles_described_functions() {
  emulate -L zsh

  local config_dir="${ZSH_CONFIG_DIR:-$HOME/dotfiles/zsh}"
  local tab=$'\t'
  local -a files

  files=(
    "$config_dir"/functions/*.zsh(N)
    "$config_dir"/local/*.zsh(N)
  )

  if (( ${#files[@]} == 0 )); then
    return 0
  fi

  awk '
    /^[[:space:]]*# @desc[[:space:]]+/ {
      description = $0
      sub(/^[[:space:]]*# @desc[[:space:]]+/, "", description)
      next
    }
    /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)[[:space:]]*\{/ {
      name = $0
      sub(/^[[:space:]]*/, "", name)
      sub(/[[:space:]]*\(\)[[:space:]]*\{.*/, "", name)
      if (name !~ /^_/ && description != "") {
        print name "\t" description
      }
      description = ""
      next
    }
    /^[[:space:]]*$/ { next }
    { description = "" }
  ' "${files[@]}" | LC_ALL=C sort -u -t "$tab" -k1,1
}

_dotfiles_custom_alias_names() {
  emulate -L zsh

  local config_dir="${ZSH_CONFIG_DIR:-$HOME/dotfiles/zsh}"
  local -a files

  files=(
    "$config_dir"/aliases/*.zsh(N)
    "$config_dir"/local/*.zsh(N)
  )

  if (( ${#files[@]} == 0 )); then
    return 0
  fi

  awk '
    /^[[:space:]]*alias[[:space:]]+[A-Za-z_][A-Za-z0-9_]*=/ {
      name = $0
      sub(/^[[:space:]]*alias[[:space:]]+/, "", name)
      sub(/=.*/, "", name)
      print name
    }
  ' "${files[@]}" | LC_ALL=C sort -u
}

# @desc List described custom functions as a formatted table.
fns() {
  emulate -L zsh

  local -a rows
  rows=("${(@f)$(_dotfiles_described_functions)}")
  rows=("${(@)rows:#}")

  if (( ${#rows[@]} == 0 )); then
    print "No described functions found."
    return 0
  fi

  _dotfiles_print_table $'FUNCTION\tDESCRIPTION' "${rows[@]}"
}

# @desc List custom aliases as a formatted table.
aliases() {
  emulate -L zsh

  local name
  local -a names rows

  names=("${(@f)$(_dotfiles_custom_alias_names)}")
  names=("${(@)names:#}")

  if (( ${#names[@]} == 0 )); then
    print "No custom aliases found."
    return 0
  fi

  for name in "${names[@]}"; do
    if (( ${+aliases[$name]} )); then
      rows+=("${name}"$'\t'"${aliases[$name]}")
    fi
  done

  if (( ${#rows[@]} == 0 )); then
    print "No loaded custom aliases found."
    return 0
  fi

  _dotfiles_print_table $'ALIAS\tCOMMAND' "${rows[@]}"
}
