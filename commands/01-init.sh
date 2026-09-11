cmd_init_ai() {
  log "Initializing .ai/ structure..."
  mkdir -p "$AI_DIR" "${RULES_DIR:-$AI_DIR/rules}" "${SKILLS_DIR:-$AI_DIR/skills}"
  if [[ ! -f "$AI_DIR/AGENTS.md" ]]; then
    cat > "$AI_DIR/AGENTS.md" <<'AGENTS'
# Project AI Instructions
## Core Philosophy
Be clear, concise, and correct.
AGENTS
  fi
  log "✅ .ai/ initialized"

  local gitignore=".gitignore"
  local marker="# Simply CLI"
  local block
  block=$(cat <<'GITIGNORE'
# Simply CLI
# Sync cache (remote skills/files fetched at sync time)
.simply/cache/

# Timestamped backups created before overwriting synced files
*.bak.*
GITIGNORE
)

  if [[ -f "$gitignore" ]]; then
    if grep -q "$marker" "$gitignore"; then
      log ".gitignore already has Simply CLI entries"
    else
      printf '\n%s\n' "$block" >> "$gitignore"
      log "✅ Appended Simply CLI entries to .gitignore"
    fi
  else
    printf '%s\n' "$block" > "$gitignore"
    log "✅ Created .gitignore with Simply CLI entries"
  fi
}
