cmd_status() {
  echo "=== Simply AI Config Status ==="
  [[ -d "$AI_DIR" ]] && echo "✅ AI dir ($AI_DIR) exists" || echo "❌ AI dir ($AI_DIR) missing"
  local rules_dir="${RULES_DIR:-$AI_DIR/rules}"
  local skills_dir="${SKILLS_DIR:-$AI_DIR/skills}"
  local rules_count=0 skills_count=0
  [[ -d "$rules_dir" ]] && rules_count=$(find "$rules_dir" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  [[ -d "$skills_dir" ]] && skills_count=$(find "$skills_dir" -mindepth 2 -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  echo "Rules ($rules_dir): $rules_count files"
  echo "Skills ($skills_dir): $skills_count installed"
  echo "Dry Run mode: ${DRY_RUN:-false}"
  echo "Backup Existing: ${BACKUP_EXISTING:-true}"
  echo ""
  echo "Configured Tools (${#TOOLS[@]}):"
  for tool_entry in "${TOOLS[@]}"; do
    local tool="${tool_entry%%:*}"
    local target="${tool_entry#*:}"
    echo "  - $tool → $target"
  done

  if [[ ${#SKILLS_REMOTE[@]} -gt 0 ]]; then
    echo ""
    echo "Remote Skills (${#SKILLS_REMOTE[@]}):"
    for entry in "${SKILLS_REMOTE[@]}"; do
      local name type url path ref
      IFS='|' read -r name type url path ref <<< "$entry"
      if [[ "$type" == "local" ]]; then
        echo "  - $name (type: local, path: $path)"
      else
        echo "  - $name (type: $type, url: $url, ref: $ref)"
      fi
    done
  fi

  if [[ ${#FILES[@]} -gt 0 ]]; then
    echo ""
    echo "Files (${#FILES[@]}):"
    for entry in "${FILES[@]}"; do
      local dest type url path ref
      IFS='|' read -r dest type url path ref <<< "$entry"
      if [[ "$type" == "local" ]]; then
        echo "  - $dest ← local:$path"
      else
        echo "  - $dest ← $type:$url@$ref"
      fi
    done
  fi

  if [[ ${#HOOKS_POST_SYNC[@]} -gt 0 ]]; then
    echo ""
    echo "Hooks (post_sync):"
    for hook in "${HOOKS_POST_SYNC[@]}"; do
      echo "  - $hook"
    done
  fi

  echo ""
  echo "Features:"
  echo "  enable_sync: ${FEATURE_ENABLE_SYNC:-true}"
  echo "  enable_create: ${FEATURE_ENABLE_CREATE:-true}"
}
