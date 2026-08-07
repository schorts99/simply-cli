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

load_config() {
  TOOLS=(
    "cursor:.cursor"
    "claude:.claude"
    "copilot:.github"
    "antigravity:ANTIGRAVITY.md"
    "codex:AGENTS.md"
  )

  [[ -f "$CONFIG_FILE" ]] || return

  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
}

load_config

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
# Override sync targets here if needed.
#

# The default configuration is:
#
# TOOLS=(
#   "cursor:.cursor"
#   "claude:.claude"
#   "copilot:.github"
#   "gemini:GEMINI.md"
#   "codex:AGENTS.md"
# )
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
