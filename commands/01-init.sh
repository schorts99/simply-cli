cmd_init_ai() {
  log "Initializing .ai/ structure..."
  mkdir -p "$AI_DIR/rules" "$AI_DIR/skills"
  if [[ ! -f "$AI_DIR/AGENTS.md" ]]; then
    cat > "$AI_DIR/AGENTS.md" <<'AGENTS'
# Project AI Instructions
## Core Philosophy
Be clear, concise, and correct.
AGENTS
  fi
  log "✅ .ai/ initialized"
}
