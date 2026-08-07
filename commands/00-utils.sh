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
  local src="$3"
  local dest="$4"

  case "$tool" in
    cursor)
      if [[ "$kind" == "rules" ]]; then
        cat > "$dest" <<EOF
---
$(cat "$src")
EOF
      else
        cp "$src" "$dest"
      fi
      ;;

    claude)
      cp "$src" "$dest"
      ;;

    copilot)
      if [[ "$kind" == "rules" ]]; then
        cat > "$dest" <<EOF
---
## applyTo: "**/*"

$(cat "$src")
EOF
      else
        cp "$src" "$dest"
      fi
      ;;

    *)
      error "Unknown tool: $tool"
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
    return 0
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
  echo
  echo "## $title"
  echo
  echo "Source of truth: \`$source_dir/\`"
  echo

  shopt -s nullglob

  for src in "$source_dir"/*.md; do
    local name
    local rel

    name=$(basename "$src" .md)
    rel="${source_dir}/$(basename "$src")"

    if [[ "$tool" == "gemini" ]]; then
      echo "- [$name]($rel) — or \`@$rel\`"
    else
      echo "- [$name]($rel)"
    fi
  done

  shopt -u nullglob

  echo
  echo "*Synced via Simply*"
}
