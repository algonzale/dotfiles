usecodex() {
  local config="$HOME/.codex/config.toml"
  local profile_arg="$1"
  local profile=""
  local codex_bin=""
  local -a codex_args
  local -a config_overrides

  if [ ! -f "$config" ]; then
    echo "❌ Codex config not found at $config"
    return 1
  fi

  if command -v npm >/dev/null 2>&1; then
    local npm_bin
    npm_bin="$(npm bin -g 2>/dev/null)"
    if [ -n "$npm_bin" ] && [ -x "$npm_bin/codex" ]; then
      codex_bin="$npm_bin/codex"
    fi
  fi

  if [ -z "$codex_bin" ]; then
    codex_bin="$(command -v codex 2>/dev/null)"
  fi

  if [ -z "$codex_bin" ]; then
    echo "❌ codex not found. Install with: npm i -g @openai/codex"
    return 1
  fi

  if [ -n "$profile_arg" ] && [ "${profile_arg#-}" = "$profile_arg" ]; then
    profile="$profile_arg"
    shift
  else
    if ! command -v fzf >/dev/null 2>&1; then
      echo "❌ fzf is required to choose a Codex profile interactively"
      return 1
    fi

    local entries
    entries=$(python3 - "$config" <<'PY'
import sys
path = sys.argv[1]
top = {"model": None, "model_reasoning_effort": None, "personality": None}
profiles = []
current = None
data = {}

def commit():
    global current, data
    if current:
        profiles.append((current, data))
    current = None
    data = {}

with open(path, "r", encoding="utf-8") as fh:
    for raw in fh:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            commit()
            section = line[1:-1]
            if section.startswith("profiles."):
                current = section[len("profiles."):]
            continue
        if "=" not in line:
            continue
        key, val = [part.strip() for part in line.split("=", 1)]
        if val.startswith('"') and val.endswith('"'):
            val = val[1:-1]
        if current:
            if key in top:
                data[key] = val
        else:
            if key in top:
                top[key] = val

commit()
default_model = top.get("model") or "default"
default_effort = top.get("model_reasoning_effort") or "-"
default_personality = top.get("personality") or "-"
rows = [("(default)", default_model, default_effort, default_personality)]
for name, data in profiles:
    model = data.get("model") or default_model
    effort = data.get("model_reasoning_effort") or default_effort
    personality = data.get("personality") or default_personality
    rows.append((name, model, effort, personality))

headers = ("PROFILE", "MODEL", "REASONING", "PERSONALITY")
widths = [len(item) for item in headers]
for row in rows:
    for idx, val in enumerate(row):
        widths[idx] = max(widths[idx], len(val))

header_row = (
    f"{headers[0]:<{widths[0]}}  {headers[1]:<{widths[1]}}  "
    f"{headers[2]:<{widths[2]}}  {headers[3]:<{widths[3]}}"
)
print(f"__header__\t{header_row}")
for profile_name, model, effort, personality in rows:
    display = (
        f"{profile_name:<{widths[0]}}  {model:<{widths[1]}}  "
        f"{effort:<{widths[2]}}  {personality:<{widths[3]}}"
    )
    print(f"{profile_name}\t{display}")
PY
)

    if [ -z "$entries" ]; then
      echo "❌ No profiles found in $config"
      return 1
    fi

    local selection
    selection=$(printf "%s\n" "$entries" | fzf \
      --prompt="Choose Codex profile: " \
      --delimiter=$'\t' \
      --with-nth=2 \
      --header-lines=1 \
      --header="ENTER select profile | ESC cancel")

    if [ -z "$selection" ]; then
      echo "❌ No profile selected"
      return 1
    fi

    profile="${selection%%$'\t'*}"
    if [ "$profile" = "(default)" ]; then
      profile=""
    fi
  fi

  local overrides=""
  if command -v fzf >/dev/null 2>&1; then
    local overrides_entries
    overrides_entries=$(python3 <<'PY'
rows = [
    ("none", "No overrides", "Keep selected profile values"),
    ("model", "Model", "Override model ID (example: gpt-5.4)"),
    ("reasoning", "Reasoning", "Override model_reasoning_effort"),
    ("personality", "Personality", "Override behavior preset"),
    ("trust", "Trust", "Set trust_level for current project path"),
    ("sandbox", "Sandbox", "Command execution isolation mode"),
    ("approval", "Approval", "When command approval is required"),
    ("search", "Search", "Enable web search for this session"),
]
headers = ("OVERRIDE", "AREA", "DESCRIPTION")
widths = [len(item) for item in headers]
for row in rows:
    for idx, val in enumerate(row):
        widths[idx] = max(widths[idx], len(val))

header_row = (
    f"{headers[0]:<{widths[0]}}  {headers[1]:<{widths[1]}}  {headers[2]:<{widths[2]}}"
)
print(f"__header__\t{header_row}")
for key, area, desc in rows:
    display = f"{key:<{widths[0]}}  {area:<{widths[1]}}  {desc:<{widths[2]}}"
    print(f"{key}\t{display}")
PY
)
    overrides=$(printf "%s\n" "$overrides_entries" | fzf \
      --multi \
      --prompt="Overrides (optional): " \
      --delimiter=$'\t' \
      --with-nth=2 \
      --header-lines=1 \
      --header="TAB toggles option | ENTER continue | ESC continue with no overrides")
  fi

  local -a override_list
  if [ -n "$overrides" ]; then
    override_list=("${(@f)$(printf "%s\n" "$overrides" | cut -f1)}")
  else
    override_list=()
  fi

  local no_overrides_selected=0
  local selected_override
  for selected_override in "${override_list[@]}"; do
    if [ "$selected_override" = "none" ]; then
      no_overrides_selected=1
      break
    fi
  done
  if [ "$no_overrides_selected" -eq 1 ]; then
    override_list=()
  fi

  local opt
  for opt in "${override_list[@]}"; do
    case "$opt" in
      model)
        local model_entries
        model_entries=$(python3 - "$config" <<'PY'
import sys
path = sys.argv[1]
models = {}
current = None
data = {}
top_model = None

def commit():
    global current, data
    if current and data.get("model"):
        models.setdefault(data["model"], set()).add(current)
    current = None
    data = {}

with open(path, "r", encoding="utf-8") as fh:
    for raw in fh:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            commit()
            section = line[1:-1]
            if section.startswith("profiles."):
                current = section[len("profiles."):]
            continue
        if "=" not in line:
            continue
        key, val = [part.strip() for part in line.split("=", 1)]
        if val.startswith('"') and val.endswith('"'):
            val = val[1:-1]
        if current:
            if key == "model":
                data["model"] = val
        else:
            if key == "model":
                top_model = val

commit()
if top_model:
    models.setdefault(top_model, set()).add("default")
for model in sorted(models):
    sources = ", ".join(sorted(models[model]))
    print(f"{model}\tSeen in: {sources}")
PY
)
        local model_menu
        model_menu=$'(keep profile)\tUse model from selected profile/default\n(custom)\tEnter model ID manually'
        if [ -n "$model_entries" ]; then
          model_menu+=$'\n'"$model_entries"
        fi

        local model_selection
        model_selection=$(printf "%s\n" "$model_menu" | fzf \
          --prompt="Model: " \
          --delimiter=$'\t' \
          --with-nth=1,2 \
          --header=$'ENTER select | ESC skip\nvalue\tdescription')
        local model_choice="${model_selection%%$'\t'*}"

        if [ -z "$model_selection" ]; then
          :
        elif [ "$model_choice" = "(custom)" ]; then
          local custom_model
          read "custom_model?Custom model: "
          if [ -n "$custom_model" ]; then
            config_overrides+=("model=\"$custom_model\"")
          fi
        elif [ "$model_choice" = "(keep profile)" ]; then
          :
        else
          local model="$model_choice"
          config_overrides+=("model=\"$model\"")
        fi
        ;;
      reasoning)
        local effort_selection
        local reasoning_menu
        reasoning_menu=$'keep\tUse profile/default value\nlow\tLower latency, lighter reasoning\nmedium\tBalanced latency and depth\nhigh\tMaximum depth, slower responses'
        effort_selection=$(printf "%s\n" "$reasoning_menu" | fzf \
          --prompt="Reasoning effort: " \
          --delimiter=$'\t' \
          --with-nth=1,2 \
          --header=$'ENTER select | ESC skip\nvalue\tdescription')
        effort_selection="${effort_selection%%$'\t'*}"
        if [ -n "$effort_selection" ] && [ "$effort_selection" != "keep" ]; then
          config_overrides+=("model_reasoning_effort=\"$effort_selection\"")
        fi
        ;;
      personality)
        local personality_entries
        personality_entries=$(python3 - "$config" <<'PY'
import sys
path = sys.argv[1]
values = set()
current = None
data = {}
top_personality = None

def commit():
    global current, data
    if current and data.get("personality"):
        values.add(data["personality"])
    current = None
    data = {}

with open(path, "r", encoding="utf-8") as fh:
    for raw in fh:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            commit()
            section = line[1:-1]
            if section.startswith("profiles."):
                current = section[len("profiles."):]
            continue
        if "=" not in line:
            continue
        key, val = [part.strip() for part in line.split("=", 1)]
        if val.startswith('"') and val.endswith('"'):
            val = val[1:-1]
        if current:
            if key == "personality":
                data["personality"] = val
        else:
            if key == "personality":
                top_personality = val

commit()
if top_personality:
    values.add(top_personality)
for item in sorted(values):
    print(item)
PY
)
        local personality_menu
        personality_menu=$'(keep profile)\tUse personality from selected profile/default\n(custom)\tEnter personality value manually'
        if [ -n "$personality_entries" ]; then
          local personality_item
          while IFS= read -r personality_item; do
            [ -z "$personality_item" ] && continue
            personality_menu+=$'\n'"$personality_item"$'\t'"Preset from config.toml"
          done <<< "$personality_entries"
        fi

        local personality_selection
        personality_selection=$(printf "%s\n" "$personality_menu" | fzf \
          --prompt="Personality: " \
          --delimiter=$'\t' \
          --with-nth=1,2 \
          --header=$'ENTER select | ESC skip\nvalue\tdescription')
        local personality_value="${personality_selection%%$'\t'*}"

        if [ -z "$personality_selection" ]; then
          :
        elif [ "$personality_value" = "(custom)" ]; then
          local custom_personality
          read "custom_personality?Custom personality: "
          if [ -n "$custom_personality" ]; then
            config_overrides+=("personality=\"$custom_personality\"")
          fi
        elif [ "$personality_value" = "(keep profile)" ]; then
          :
        else
          config_overrides+=("personality=\"$personality_value\"")
        fi
        ;;
      trust)
        local project_root
        if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
          project_root="$(git rev-parse --show-toplevel)"
        else
          project_root="$PWD"
        fi

        local trust_selection
        local trust_menu
        trust_menu=$'keep\tUse trust_level from config/profile\ntrusted\tAllow project to run trusted workflows\nuntrusted\tTreat project as untrusted'
        trust_selection=$(printf "%s\n" "$trust_menu" | fzf \
          --prompt="Trust level for $project_root: " \
          --delimiter=$'\t' \
          --with-nth=1,2 \
          --header=$'ENTER select | ESC skip\nvalue\tdescription')
        trust_selection="${trust_selection%%$'\t'*}"
        if [ -n "$trust_selection" ] && [ "$trust_selection" != "keep" ]; then
          config_overrides+=("projects.\"$project_root\".trust_level=\"$trust_selection\"")
        fi
        ;;
      sandbox)
        local sandbox_selection
        local sandbox_menu
        sandbox_menu=$'keep\tUse sandbox mode from profile/default\nread-only\tNo file writes allowed\nworkspace-write\tAllow writes in workspace only\ndanger-full-access\tFull filesystem access (least safe)'
        sandbox_selection=$(printf "%s\n" "$sandbox_menu" | fzf \
          --prompt="Sandbox: " \
          --delimiter=$'\t' \
          --with-nth=1,2 \
          --header=$'ENTER select | ESC skip\nvalue\tdescription')
        sandbox_selection="${sandbox_selection%%$'\t'*}"
        if [ -n "$sandbox_selection" ] && [ "$sandbox_selection" != "keep" ]; then
          codex_args+=(--sandbox "$sandbox_selection")
        fi
        ;;
      approval)
        local approval_selection
        local approval_menu
        approval_menu=$'keep\tUse approval policy from profile/default\nuntrusted\tAsk when command is outside trusted scope\non-failure\tAsk only when command fails (deprecated upstream)\non-request\tModel asks when it decides approval is needed\nnever\tNever ask for approval'
        approval_selection=$(printf "%s\n" "$approval_menu" | fzf \
          --prompt="Approval policy: " \
          --delimiter=$'\t' \
          --with-nth=1,2 \
          --header=$'ENTER select | ESC skip\nvalue\tdescription')
        approval_selection="${approval_selection%%$'\t'*}"
        if [ -n "$approval_selection" ] && [ "$approval_selection" != "keep" ]; then
          codex_args+=(--ask-for-approval "$approval_selection")
        fi
        ;;
      search)
        local search_selection
        local search_menu
        search_menu=$'keep\tUse search setting from profile/default\nenable\tPass --search for this run\ndisable\tDo not pass --search flag'
        search_selection=$(printf "%s\n" "$search_menu" | fzf \
          --prompt="Web search: " \
          --delimiter=$'\t' \
          --with-nth=1,2 \
          --header=$'ENTER select | ESC skip\nvalue\tdescription')
        search_selection="${search_selection%%$'\t'*}"
        if [ "$search_selection" = "enable" ]; then
          codex_args+=(--search)
        fi
        ;;
    esac
  done

  if [ -n "$profile" ]; then
    codex_args+=(--profile "$profile")
  fi

  local override
  for override in "${config_overrides[@]}"; do
    codex_args+=(-c "$override")
  done

  if [ -n "$profile" ]; then
    echo "✅ Running Codex with profile '$profile'"
  else
    echo "✅ Running Codex with default profile"
  fi
  "$codex_bin" "${codex_args[@]}" --yolo "$@"
}
