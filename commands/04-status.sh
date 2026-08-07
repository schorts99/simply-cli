cmd_status() {
  echo "=== Simply AI Config Status ==="
  [[ -d "$AI_DIR" ]] && echo "✅ AI dir ($AI_DIR) exists" || echo "❌ AI dir ($AI_DIR) missing"
  local rules_dir="${RULES_DIR:-$AI_DIR/rules}"
  local skills_dir="${SKILLS_DIR:-$AI_DIR/skills}"
  local rules_count=0 skills_count=0
  [[ -d "$rules_dir" ]] && rules_count=$(find "$rules_dir" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  [[ -d "$skills_dir" ]] && skills_count=$(find "$skills_dir" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  echo "Rules ($rules_dir): $rules_count files"
  echo "Skills ($skills_dir): $skills_count files"
  echo "Dry Run mode: ${DRY_RUN:-true}"
  echo "Backup Existing: ${BACKUP_EXISTING:-true}"
  echo ""
  echo "Configured Tools (${#TOOLS[@]}):"
  for tool_entry in "${TOOLS[@]}"; do
    local tool="${tool_entry%%:*}"
    local target="${tool_entry#*:}"
    echo "  - $tool → $target"
  done
}

