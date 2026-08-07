#!/bin/bash

set -euo pipefail

log() {
  echo "→ $1"
}

warn() {
  echo "⚠️  $1"
}

error() {
  echo "❌ $1"
  exit 1
}

backup_file() {
  local target="$1"

  [[ -f "$target" ]] || return 0

  local backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"

  cp "$target" "$backup"

  log "Backed up → $backup"
}

write_tool_file() {
  local tool="$1"
  local kind="$2"
  local source="$3"
  local target="$4"

  case "$tool:$kind" in
    cursor:rules|cursor:skills)
      cat > "$target" <<EOF
---

$(cat "$source")
EOF
      ;;

    copilot:rules|copilot:skills)
      cat > "$target" <<EOF
---
applyTo: "**/*"
---

$(cat "$source")
EOF
      ;;

    *)
      cp "$source" "$target"
      ;;
  esac
}

sync_directory() {
  local tool="$1"
  local kind="$2"
  local target_dir="${3%/}"
  local source_dir="$4"
  local extension="$5"
  local dry_run="$6"

  [[ -d "$source_dir" ]] || return 0

  mkdir -p "$target_dir"

  shopt -s nullglob

  for src in "$source_dir"/*.md; do
    local name
    local dest

    name=$(basename "$src" .md)
    dest="$target_dir/${name}${extension}"

    if [[ "$dry_run" == true ]]; then
      log "[DRY-RUN] Would sync $tool $kind → $dest"
      continue
    fi

    backup_file "$dest"

    write_tool_file \
      "$tool" \
      "$kind" \
      "$src" \
      "$dest"

    log "$tool $kind synced → $dest"
  done

  shopt -u nullglob
}

sync_directory_cursor() {
  sync_directory cursor "$@"
}

sync_directory_claude() {
  sync_directory claude "$@"
}

sync_directory_copilot() {
  sync_directory copilot "$@"
}

sync_single_file() {
  local tool="$1"
  local target="$2"
  local content="$3"
  local dry_run="$4"

  if [[ "$dry_run" == true ]]; then
    log "[DRY-RUN] Would sync $tool → $target"
    return
  fi

  mkdir -p "$(dirname "$target")"

  backup_file "$target"

  printf '%s\n' "$content" > "$target"

  log "$tool synced → $target"
}

build_directory_index() {
  local title="$1"
  local source_dir="$2"
  local tool="$3"

  [[ -d "$source_dir" ]] || return 0

  echo "---"
  echo ""
  echo "## Available $title (source of truth: \`.ai/$(
    basename "$source_dir"
  )/\`)"
  echo ""
  echo "Modular $title live under \`.ai/$(
    basename "$source_dir"
  )/\`. Reference them when relevant:"
  echo ""

  shopt -s nullglob

  for src in "$source_dir"/*.md; do
    local name
    local rel

    name=$(basename "$src" .md)
    rel=".ai/$(basename "$source_dir")/$(basename "$src")"

    if [[ "$tool" == "gemini" ]]; then
      echo "- [$name]($rel) — or \`@$rel\`"
    else
      echo "- [$name]($rel)"
    fi
  done

  shopt -u nullglob

  echo ""
  echo "*Synced via Simply*"
}


cmd_sync_ai_rules() {
  local dry_run=false

  if [[ "${1:-}" == "--dry-run" ]]; then
    dry_run=true
    log "=== DRY RUN MODE ==="
  fi

  log "Starting sync..."

  [[ -d "$AI_DIR" ]] || cmd_init_ai

  local rules_dir="$AI_DIR/rules"
  local skills_dir="$AI_DIR/skills"
  local main_file="$AI_DIR/AGENTS.md"

  for tool_entry in "${TOOLS[@]}"; do
    local tool="${tool_entry%%:*}"
    local target="${tool_entry#*:}"

    case "$tool" in
      cursor)
        sync_directory_cursor \
          rules \
          "$target/rules" \
          "$rules_dir" \
          ".mdc" \
          "$dry_run"

        sync_directory_cursor \
          skills \
          "$target/skills" \
          "$skills_dir" \
          ".mdc" \
          "$dry_run"
        ;;

      claude)
        sync_single_file \
          claude \
          "CLAUDE.md" \
          "$(cat "$main_file" 2>/dev/null || true)" \
          "$dry_run"

        sync_directory_claude \
          rules \
          "$target/rules" \
          "$rules_dir" \
          ".md" \
          "$dry_run"

        sync_directory_claude \
          skills \
          "$target/skills" \
          "$skills_dir" \
          ".md" \
          "$dry_run"
        ;;

      copilot)
        sync_single_file \
          copilot \
          ".github/copilot-instructions.md" \
          "$(cat "$main_file" 2>/dev/null || true)" \
          "$dry_run"

        sync_directory_copilot \
          rules \
          "$target/instructions/rules" \
          "$rules_dir" \
          ".instructions.md" \
          "$dry_run"

        sync_directory_copilot \
          skills \
          "$target/instructions/skills" \
          "$skills_dir" \
          ".instructions.md" \
          "$dry_run"
        ;;

      gemini|codex)
        local content

        content=$(cat "$main_file" 2>/dev/null || true)

        content+=$'\n\n'
        content+="$(build_directory_index \
          "Rules" \
          "$rules_dir" \
          "$tool")"

        content+=$'\n\n'
        content+="$(build_directory_index \
          "Skills" \
          "$skills_dir" \
          "$tool")"

        sync_single_file \
          "$tool" \
          "$target" \
          "$content" \
          "$dry_run"
        ;;
    esac
  done

  log "✅ Sync completed"
}
