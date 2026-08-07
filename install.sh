#!/bin/bash

set -euo pipefail

SIMPLY_VERSION="v1.6.0"

mkdir -p \
  "$HOME/.local/bin" \
  "$HOME/.local/share" \
  "$HOME/.simply"

if [[ -d "commands" ]]; then
  rm -rf "$HOME/.simply/commands"
  cp -a commands "$HOME/.simply/commands"

  echo "✅ Commands installed to ~/.simply/"
else
  echo "ℹ️  No commands/ directory found — skipping"
fi

escape_sed() {
  printf '%s' "$1" | sed 's/[\/&]/\\&/g'
}

GIT_USER_NAME=$(git config user.name 2>/dev/null || echo "Author Name")
GIT_USER_EMAIL=$(git config user.email 2>/dev/null || echo "author@example.com")

if [[ -f "resources/design-doc.md" ]]; then
  cp "resources/design-doc.md" "$HOME/.simply/design-doc.md"

  AUTHOR_NAME=$(escape_sed "$GIT_USER_NAME")
  AUTHOR_EMAIL=$(escape_sed "$GIT_USER_EMAIL")

  case "$OSTYPE" in
    darwin*)
      sed -i '' \
        -e "s/AUTHOR_NAME/$AUTHOR_NAME/g" \
        -e "s/AUTHOR_EMAIL/$AUTHOR_EMAIL/g" \
        "$HOME/.simply/design-doc.md"
      ;;
    *)
      sed -i \
        -e "s/AUTHOR_NAME/$AUTHOR_NAME/g" \
        -e "s/AUTHOR_EMAIL/$AUTHOR_EMAIL/g" \
        "$HOME/.simply/design-doc.md"
      ;;
  esac

  echo "✅ design-doc.md installed to ~/.simply/"
else
  echo "ℹ️  No resources/design-doc.md found — skipping"
fi

cat > "$HOME/.local/bin/simply" <<'EOL'
#!/bin/bash

set -euo pipefail

SIMPLY_VERSION="__SIMPLY_VERSION__"

SIMPLY_DIR="$HOME/.simply"
AI_DIR=".ai"
GLOBAL_AI_DIR="$HOME/.ai-global"
CONFIG_FILE="$SIMPLY_DIR/config"

# Default tools configuration
TOOLS=(
  "cursor:.cursor"
  "claude:.claude"
  "copilot:.github"
  "antigravity:ANTIGRAVITY.md"
  "codex:AGENTS.md"
)

# Defaults when not overridden
RULES_DIR="${RULES_DIR:-$AI_DIR/rules}"
SKILLS_DIR="${SKILLS_DIR:-$AI_DIR/skills}"
DRY_RUN="${DRY_RUN:-true}"
BACKUP_EXISTING="${BACKUP_EXISTING:-true}"

load_config() {
  # Load global config (may override TOOLS and other settings)
  [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
}

# Load global config first (overriding defaults if defined)
load_config

# Project-level config overrides (TOML at .simply/config.toml or config.toml)
PROJECT_CONFIG_FILE=".simply/config.toml"
if [[ ! -f "$PROJECT_CONFIG_FILE" && -f "config.toml" ]]; then
  PROJECT_CONFIG_FILE="config.toml"
fi

if [[ -f "$PROJECT_CONFIG_FILE" ]]; then
  # parse simple TOML key = "value" lines for ai_dir, rules_dir, skills_dir
  parsed_ai_dir=$(sed -n 's/^[[:space:]]*ai_dir *= *"\(.*\)".*/\1/p' "$PROJECT_CONFIG_FILE" | tr -d '\r' | tail -n 1) || true
  if [[ -n "$parsed_ai_dir" ]]; then AI_DIR="$parsed_ai_dir"; fi

  parsed_rules_dir=$(sed -n 's/^[[:space:]]*rules_dir *= *"\(.*\)".*/\1/p' "$PROJECT_CONFIG_FILE" | tr -d '\r' | tail -n 1) || true
  if [[ -n "$parsed_rules_dir" ]]; then RULES_DIR="$parsed_rules_dir"; fi

  parsed_skills_dir=$(sed -n 's/^[[:space:]]*skills_dir *= *"\(.*\)".*/\1/p' "$PROJECT_CONFIG_FILE" | tr -d '\r' | tail -n 1) || true
  if [[ -n "$parsed_skills_dir" ]]; then SKILLS_DIR="$parsed_skills_dir"; fi

  # boolean flags: dry_run and backup_existing (true|false)
  parsed_dry_run=$(sed -n 's/^[[:space:]]*dry_run *= *\(true\|false\).*/\1/p' "$PROJECT_CONFIG_FILE" | tr -d '\r' | tail -n 1) || true
  if [[ -n "$parsed_dry_run" ]]; then DRY_RUN="$parsed_dry_run"; fi

  parsed_backup_existing=$(sed -n 's/^[[:space:]]*backup_existing *= *\(true\|false\).*/\1/p' "$PROJECT_CONFIG_FILE" | tr -d '\r' | tail -n 1) || true
  if [[ -n "$parsed_backup_existing" ]]; then BACKUP_EXISTING="$parsed_backup_existing"; fi

  # Parse tools from [tools] section: tool = "target"
  if grep -q '^\[tools\]' "$PROJECT_CONFIG_FILE"; then
    TOOLS=()
    in_tools_section=false
    while IFS= read -r line; do
      line="${line%%#*}"
      line=$(echo "$line" | sed -e 's/^[[:space:]]*//;s/[[:space:]]*$//')
      
      if [[ "$line" == "[tools]" ]]; then
        in_tools_section=true
        continue
      fi
      
      if [[ "$line" =~ ^\[ && "$in_tools_section" == true ]]; then
        break
      fi
      
      if [[ "$in_tools_section" == true && "$line" == *"="* ]]; then
        tool="${line%%=*}"
        target="${line#*=}"
        tool=$(echo "$tool" | sed -e 's/^[[:space:]]*//;s/[[:space:]]*$//')
        target=$(echo "$target" | sed -e 's/^[[:space:]]*//;s/[[:space:]]*$//' -e 's/"//g' -e "s/'//g")
        [[ -n "$tool" && -n "$target" ]] && TOOLS+=("$tool:$target")
      fi
    done < "$PROJECT_CONFIG_FILE"
  fi
fi

COMMANDS_DIR="$HOME/.simply/commands"

if [[ ! -d "$COMMANDS_DIR" ]]; then
  echo "❌ Commands directory not found: $COMMANDS_DIR"
  exit 1
fi

shopt -s nullglob

for cmd_file in "$COMMANDS_DIR"/*.sh; do
  # shellcheck disable=SC1090
  source "$cmd_file"
done

shopt -u nullglob

case "${1:-}" in
  init)
    case "${2:-}" in
      ai)
        cmd_init_ai
        ;;
      *)
        usage
        ;;
    esac
    ;;

  config)
    # Create a .simply/ directory and populate a config.toml
    cmd_config
    ;;

  create)
    case "${2:-}" in
      design-doc)
        cmd_create_design_doc
        ;;
      *)
        usage
        ;;
    esac
    ;;

  sync)
    case "${2:-}" in
      ai)
        shift 2
        cmd_sync_ai_rules "$@"
        ;;
      *)
        usage
        ;;
    esac
    ;;

  status)
    cmd_status
    ;;

  doctor)
    cmd_doctor
    ;;

  update)
    cmd_update
    ;;

  uninstall)
    cmd_uninstall
    ;;

  version|--version|-v)
    cmd_version
    ;;

  help|--help|-h)
    usage
    ;;

  *)
    usage
    ;;
esac
EOL

if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' \
    "s/__SIMPLY_VERSION__/$SIMPLY_VERSION/g" \
    "$HOME/.local/bin/simply"
else
  sed -i \
    "s/__SIMPLY_VERSION__/$SIMPLY_VERSION/g" \
    "$HOME/.local/bin/simply"
fi

chmod +x "$HOME/.local/bin/simply"

if [[ -n "${ZSH_VERSION-}" ]] || [[ "$SHELL" == *zsh* ]]; then

cat > "$HOME/.local/share/simply-completion.sh" <<'COMP'
_simply_commands=(
  'init:Initialize .ai structure'
  'config:Create project .simply config'
  'create:Create personalized design-doc.md'
  'sync:Sync configs to AI tools'
  'status:Show current AI config'
  'doctor:Run diagnostics'
  'update:Check for updates'
  'uninstall:Remove Simply CLI'
  'version:Show version'
  'help:Show help'
)

_simply() {
  local context state

  _arguments -C \
    '1: :->cmds' \
    '2: :->subcmds'

  case $state in
    cmds)
      _describe 'command' _simply_commands
      ;;

    subcmds)
      case $words[2] in
        init)
          _values 'subcommand' ai
          ;;

        create)
          _values 'subcommand' design-doc
          ;;

        sync)
          _values 'subcommand' ai
          ;;
      esac
      ;;
  esac
}

compdef _simply simply
COMP
else
cat > "$HOME/.local/share/simply-completion.sh" <<'COMP'
_simply_completions() {
  local cur prev

  COMPREPLY=()

  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prev" in
    init)
      COMPREPLY=($(compgen -W "ai" -- "$cur"))
      return
      ;;

    create)
      COMPREPLY=($(compgen -W "design-doc" -- "$cur"))
      return
      ;;

    sync)
      COMPREPLY=($(compgen -W "ai" -- "$cur"))
      return
      ;;
  esac


  COMPREPLY=(
    $(compgen -W \
      "init config create sync status doctor update uninstall version help" \
      -- "$cur")
  )
}

complete -F _simply simply
COMP
fi

setup_path() {
  local rc_file

  if [[ -n "${ZSH_VERSION-}" ]] || [[ "$SHELL" == *zsh* ]]; then
    rc_file="$HOME/.zshrc"
  else
    rc_file="$HOME/.bashrc"
  fi

  touch "$rc_file"

  if ! grep -Fq '.local/bin' "$rc_file"; then
    {
      echo
      echo '# Simply CLI'
      echo 'export PATH="$HOME/.local/bin:$PATH"'
    } >> "$rc_file"

    echo "✅ Added ~/.local/bin to $rc_file"
  else
    echo "✅ ~/.local/bin already in PATH"
  fi
}


setup_completion() {
  local rc_file

  if [[ -n "${ZSH_VERSION-}" ]] || [[ "$SHELL" == *zsh* ]]; then
    rc_file="$HOME/.zshrc"
  else
    rc_file="$HOME/.bashrc"
  fi

  touch "$rc_file"

  if ! grep -Fq 'simply-completion.sh' "$rc_file"; then
    {
      echo
      echo '# Simply CLI completion'
      echo 'source "$HOME/.local/share/simply-completion.sh"'
    } >> "$rc_file"

    echo "✅ Added completion to $rc_file"
  else
    echo "✅ Completion already configured"
  fi
}

if [[ ! -f "$HOME/.simply/config" ]]; then

cat > "$HOME/.simply/config" <<'EOF'
# Simply CLI Configuration
#
# This global config is sourced as bash, allowing you to override variables.
#
# To override TOOLS, define the array:
#
# TOOLS=(
#   "cursor:.cursor"
#   "claude:.claude"
#   "copilot:.github"
#   "antigravity:ANTIGRAVITY.md"
#   "codex:AGENTS.md"
# )
#
# For project-level overrides, use .simply/config.toml with the [tools] table:
#
# [tools]
# cursor = ".cursor"
# claude = ".claude"
# copilot = ".github"
# antigravity = "ANTIGRAVITY.md"
# codex = "AGENTS.md"
#
# Config precedence (lowest to highest):
# 1. Default TOOLS array (built into simply)
# 2. Global config ($HOME/.simply/config) - bash format
# 3. Project config (.simply/config.toml) - TOML format [tools] table
EOF
fi

setup_path
setup_completion

echo
echo "✅ Simply CLI $SIMPLY_VERSION installed successfully!"
echo
echo "Try:"
echo "  simply doctor"
echo "  simply init ai"
echo "  simply create design-doc"
echo "  simply sync ai --dry-run"
echo "  simply --version"
