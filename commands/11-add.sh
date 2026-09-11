cmd_add() {
  local kind="${1:-}"
  local name="${2:-}"
  local force="${3:-}"

  local ai_dir="${AI_DIR:-.ai}"
  local rules_dir="${RULES_DIR:-$ai_dir/rules}"
  local skills_dir="${SKILLS_DIR:-$ai_dir/skills}"

  case "$kind" in
    rule)
      if [[ -z "$name" ]]; then
        error "Usage: simply add rule <name>"
      fi

      local target="$rules_dir/${name}.md"

      if [[ -f "$target" && "$force" != "--force" ]]; then
        error "$target already exists. Use --force to overwrite."
      fi

      mkdir -p "$rules_dir"

      cat > "$target" <<EOF
# ${name}

<!-- Describe this rule: what behaviour it enforces and when it applies. -->
EOF

      log "Created rule → $target"
      ;;

    skill)
      if [[ -z "$name" ]]; then
        error "Usage: simply add skill <name>"
      fi

      local target_dir="$skills_dir/${name}"
      local target="$target_dir/SKILL.md"

      if [[ -d "$target_dir" && "$force" != "--force" ]]; then
        error "$target_dir already exists. Use --force to overwrite."
      fi

      mkdir -p "$target_dir"

      cat > "$target" <<EOF
# ${name}

## Description
<!-- What this skill does -->

## Usage
<!-- When and how to invoke this skill -->

## Steps
<!-- Ordered steps or instructions -->
EOF

      log "Created skill → $target"
      ;;

    *)
      error "Unknown add target: '${kind}'. Use 'rule' or 'skill'."
      ;;
  esac
}
