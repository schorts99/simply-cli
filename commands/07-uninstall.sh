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

  if [[ -n "${ZSH_VERSION-}" ]] || [[ "$SHELL" == *zsh* ]]; then
    rc_file="$HOME/.zshrc"
  else
    rc_file="$HOME/.bashrc"
  fi

  if [[ -f "$rc_file" ]]; then
    if [[ "$OSTYPE" == darwin* ]]; then
      sed -i '' '/# Simply CLI$/{ N; /\n.*export PATH.*\.local\/bin/d; }' "$rc_file"
      sed -i '' '/# Simply CLI completion$/{ N; /\nsource.*simply-completion\.sh/d; }' "$rc_file"
    else
      sed -i '/# Simply CLI$/{ N; /\n.*export PATH.*\.local\/bin/d; }' "$rc_file"
      sed -i '/# Simply CLI completion$/{ N; /\nsource.*simply-completion\.sh/d; }' "$rc_file"
    fi
    echo "Cleaned up shell rc ($rc_file)"
  fi

  echo "Simply CLI uninstalled."
}
