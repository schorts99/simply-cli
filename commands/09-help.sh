usage() {
  cat << EOF
Simply CLI v$SIMPLY_VERSION

Usage: simply <command> [options]

Commands:
  init ai                  Initialize .ai/ structure
  create design-doc        Create personalized design-doc.md
  sync ai [--dry-run]      Sync configs to AI tools
  status                   Show current AI config status
  doctor                   Run diagnostics
  update                   Check for updates
  uninstall                Remove Simply CLI
  version                  Show version
  help                     Show this help

Options:
  --dry-run                Show what would be done without changes
EOF
  exit 1
}
