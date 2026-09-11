cmd_doctor() {
  echo "=== Simply Doctor ==="

  # ── PATH check ────────────────────────────────────────────────────────────
  if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    echo "✅ ~/.local/bin is in PATH"
  else
    warn "~/.local/bin is NOT in PATH"
    echo 'Add: export PATH="$HOME/.local/bin:$PATH"'
  fi

  # ── .ai/ directory + rule/skill counts (minimal inline check) ─────────────
  if [[ -d "$AI_DIR" ]]; then
    local rules_dir="${RULES_DIR:-$AI_DIR/rules}"
    local skills_dir="${SKILLS_DIR:-$AI_DIR/skills}"

    local rules_count=0 skills_count=0
    [[ -d "$rules_dir" ]] && \
      rules_count=$(find "$rules_dir" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    [[ -d "$skills_dir" ]] && \
      skills_count=$(find "$skills_dir" -mindepth 2 -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')

    echo "✅ .ai/ directory found ($AI_DIR)"
    echo "   Rules:  $rules_count file(s) ($rules_dir)"
    echo "   Skills: $skills_count installed ($skills_dir)"
  else
    warn ".ai/ not found ($AI_DIR). Run: simply init ai"
  fi

  # ── Tool target staleness check ───────────────────────────────────────────
  echo ""
  echo "Tool configurations:"
  for tool_entry in "${TOOLS[@]}"; do
    local tool="${tool_entry%%:*}"
    local path="${tool_entry#*:}"

    if [[ -f "$path" ]]; then
      # Single-file target: check it's non-empty
      if [[ -s "$path" ]]; then
        echo "✅ $tool ($path)"
      else
        warn "$tool — file exists but is empty, not synced or empty ($path)"
      fi
    elif [[ -d "$path" ]]; then
      # Directory target: check it contains at least one file
      local first_file
      first_file=$(find "$path" -type f | head -1)
      if [[ -n "$first_file" ]]; then
        echo "✅ $tool ($path)"
      else
        warn "$tool — directory exists but is empty, not synced or empty ($path)"
      fi
    else
      warn "$tool not synced ($path)"
    fi
  done

  # ── Network tool availability ─────────────────────────────────────────────
  echo ""
  local has_network_tool=false
  if command -v curl >/dev/null 2>&1; then
    echo "✅ curl is available"
    has_network_tool=true
  elif command -v wget >/dev/null 2>&1; then
    echo "✅ wget is available"
    has_network_tool=true
  else
    warn "neither curl nor wget found — required for git-type skills and files"
  fi

  # ── git-type entries that need a network tool ──────────────────────────────
  if [[ "$has_network_tool" == false ]]; then
    local git_skills=0 git_files=0

    for entry in "${SKILLS_REMOTE[@]+"${SKILLS_REMOTE[@]}"}"; do
      local s_type
      IFS='|' read -r _ s_type _ _ _ <<< "$entry"
      [[ "$s_type" == "git" ]] && (( git_skills++ )) || true
    done

    for entry in "${FILES[@]+"${FILES[@]}"}"; do
      local f_type
      IFS='|' read -r _ f_type _ _ _ <<< "$entry"
      [[ "$f_type" == "git" ]] && (( git_files++ )) || true
    done

    if (( git_skills > 0 || git_files > 0 )); then
      warn "$git_skills git-type skill(s) and $git_files git-type file(s) will be skipped without curl/wget"
    fi
  fi

  # ── Post-sync hooks ────────────────────────────────────────────────────────
  echo ""
  if [[ ${#HOOKS_POST_SYNC[@]} -gt 0 ]]; then
    echo "Post-sync hooks (${#HOOKS_POST_SYNC[@]}) — will run after simply sync ai:"
    for hook in "${HOOKS_POST_SYNC[@]}"; do
      echo "   → $hook"
    done
  else
    echo "No post-sync hooks configured."
  fi

  # ── Version ───────────────────────────────────────────────────────────────
  echo ""
  echo "Version: $SIMPLY_VERSION"
}
