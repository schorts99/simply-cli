cmd_status() {
  echo "=== Simply AI Config Status ==="
  [[ -d "$AI_DIR" ]] && echo "✅ .ai/ exists" || echo "❌ .ai/ missing"
  local rules_count=0 skills_count=0
  [[ -d "$AI_DIR/rules" ]] && rules_count=$(find "$AI_DIR/rules" -type f -name "*.md" 2>/dev/null | wc -l)
  [[ -d "$AI_DIR/skills" ]] && skills_count=$(find "$AI_DIR/skills" -type f -name "*.md" 2>/dev/null | wc -l)
  echo "Rules: $rules_count files"
  echo "Skills: $skills_count files"
}
