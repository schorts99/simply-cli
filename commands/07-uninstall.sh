cmd_uninstall() {
  echo "⚠️  This will remove Simply CLI. Continue? (y/N)"
  read -r confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi

  rm -f "$HOME/.local/bin/simply"
  rm -rf "$SIMPLY_DIR"
  rm -f "$HOME/.local/share/simply-completion.sh"
  echo "Simply CLI uninstalled."
}
