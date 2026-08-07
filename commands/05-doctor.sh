cmd_doctor() {
  echo "=== Simply Doctor ==="
  if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    echo "✅ ~/.local/bin is in PATH"
  else
    warn "~/.local/bin is NOT in PATH"
    echo 'Add: export PATH="$HOME/.local/bin:$PATH"'
  fi

  if [[ -d "$AI_DIR" ]]; then
    echo "✅ .ai/ directory found"
    cmd_status
  else
    warn ".ai/ not found. Run: simply init ai"
  fi

  echo ""
  echo "Tool configurations:"
  for tool_entry in "${TOOLS[@]}"; do
    local tool=${tool_entry%%:*}
    local path=${tool_entry#*:}
    [[ -f "$path" ]] && echo "✅ $tool" || warn "$tool not synced"
  done

  echo ""
  echo "Version: $SIMPLY_VERSION"
}
