unalias projects 2>/dev/null
unalias pgmtcode 2>/dev/null

_open_selected_subdirectory() {
  local base_dir="$1"
  local prompt="$2"
  local selection=""
  local target_dir=""
  local initial_query="$3"
  local -a directories
  local -a fzf_args

  if ! command -v fzf >/dev/null 2>&1; then
    echo "❌ fzf is required to choose a directory interactively"
    return 1
  fi

  if [ ! -d "$base_dir" ]; then
    echo "❌ Directory not found: $base_dir"
    return 1
  fi

  directories=("$base_dir"/*(/N))
  if [ ${#directories[@]} -eq 0 ]; then
    echo "❌ No subdirectories found in $base_dir"
    return 1
  fi

  fzf_args=(
    --prompt="$prompt"
    --header="ENTER open directory | ESC cancel"
  )

  if [ -n "$initial_query" ]; then
    fzf_args+=(--query="$initial_query")
  fi

  selection=$(
    printf "%s\n" "${directories[@]##*/}" | LC_ALL=C sort | fzf "${fzf_args[@]}"
  )

  if [ -z "$selection" ]; then
    echo "❌ No directory selected"
    return 1
  fi

  target_dir="$base_dir/$selection"
  builtin cd "$target_dir" || return 1
  lt
}

# @desc Jump into a directory from PROJECTS_DIR using fzf.
projects() {
  if [ -z "${PROJECTS_DIR:-}" ]; then
    echo "❌ PROJECTS_DIR is not set. Define it in zsh/local/machine.zsh"
    return 1
  fi

  _open_selected_subdirectory "$PROJECTS_DIR" "Choose project: " "$*"
}

# @desc Jump into a directory from PGMTCODE_DIR using fzf.
pgmtcode() {
  if [ -z "${PGMTCODE_DIR:-}" ]; then
    echo "❌ PGMTCODE_DIR is not set. Define it in zsh/local/machine.zsh"
    return 1
  fi

  _open_selected_subdirectory "$PGMTCODE_DIR" "Choose codebase: " "$*"
}
