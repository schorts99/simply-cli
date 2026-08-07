cmd_doctor() {
  echo "=== Simply Doctor ==="
  if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    echo "✅ ~/.local/bin is in PATH"
  else
    warn "~/.local/bin is NOT in PATH"
    echo 'Add: export PATH="$HOME/.local/bin:$PATH"'
  fi

  if [[ -d "$AI_DIR" ]]; then
    echo "✅ .ai/ directory found ($AI_DIR)"
    cmd_status
  else
    warn ".ai/ not found ($AI_DIR). Run: simply init ai"
  fi

  echo ""
  echo "Tool configurations:"
  for tool_entry in "${TOOLS[@]}"; do
    local tool=${tool_entry%%:*}
    local path=${tool_entry#*:}
    if [[ -e "$path" ]]; then
      echo "✅ $tool ($path)"
    else
      warn "$tool not synced ($path)"
    fi
  done

  echo ""
  echo "Version: $SIMPLY_VERSION"
}

