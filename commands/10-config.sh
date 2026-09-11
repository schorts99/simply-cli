cmd_config() {
  log "Creating .simply/ and config.toml in the current project..."

  local target_dir=".simply"
  local cfg_file="$target_dir/config.toml"

  mkdir -p "$target_dir"

  # Backup existing config if present
  backup_file "$cfg_file"

  # Derive project name from current directory or git if available
  local project_name
  if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
    project_name=$(basename "$(git rev-parse --show-toplevel)")
  else
    project_name=$(basename "$(pwd)")
  fi

  cat > "$cfg_file" <<EOF
# Simply project configuration
# Edit values below. This file is TOML — comments start with #.

version = 1

[project]
name = "${project_name}"
# optional fields
description = "A short description of the project"
license = "MIT"
repository = ""

# authors is an array of tables
[[project.authors]]
name = "Your Name"
email = "you@example.com"

# Global settings for simply commands
[settings]
# Where AI source files live relative to project root
ai_dir = ".ai"
rules_dir = ".ai/rules"
skills_dir = ".ai/skills"
# Default behaviour for sync operations
dry_run = true
backup_existing = true

# Map of tool -> target path (used by sync)
[tools]
# Example: cursor tool writes to .cursor/
cursor = ".cursor"
claude = ".claude"
copilot = ".github"
antigravity = "ANTIGRAVITY.md"
codex = "AGENTS.md"

# Root-level file syncs — mirrors the [[skills]] source structure.
# Each [[files]] entry names a destination and a [files.source] sub-table.

# Local file — copied as-is from the project tree:
# [[files]]
# dest = "AGENTS.md"
# [files.source]
# type = "local"
# path = ".ai/AGENTS.md"

# Git file — fetched from a repo at a specific ref:
# [[files]]
# dest = "DESIGN.md"
# [files.source]
# type = "git"
# url  = "https://github.com/org/repo"
# path = "docs/DESIGN.md"
# ref  = "main"

# Example set of skills (array of tables)
[[skills]]
name = "example-skill"
[skills.source]
# type: "git" or "local"
type = "git"
url = "https://github.com/org/ai-skills"
path = "example-skill"
ref = "main"

[[skills]]
name = "local-skill"
[skills.source]
type = "local"
path = "./skills/local-skill"

# Hooks — shell commands run after certain simply operations
[hooks]
# post_sync runs after every successful \`simply sync ai\`
# accepts a single string or an array of strings
post_sync = ["echo 'synced'"]

# Feature flags — set to false to disable a command entirely
[features]
enable_sync = true
enable_create = true

# Notes: use \`simply config\` to re-generate this file (it will back up existing files)
EOF

  log "✅ Created $cfg_file"
  log "Edit $cfg_file to customize project metadata, skills, and tool targets"
}

cmd_config_show() {
  echo "=== Effective Configuration ==="
  echo ""

  echo "Settings:"
  printf '  %-16s = %s\n' "ai_dir"          "${AI_DIR:-.ai}"
  printf '  %-16s = %s\n' "rules_dir"        "${RULES_DIR:-${AI_DIR:-.ai}/rules}"
  printf '  %-16s = %s\n' "skills_dir"       "${SKILLS_DIR:-${AI_DIR:-.ai}/skills}"
  printf '  %-16s = %s\n' "dry_run"          "${DRY_RUN:-true}"
  printf '  %-16s = %s\n' "backup_existing"  "${BACKUP_EXISTING:-true}"
  echo ""

  local tool_count=${#TOOLS[@]}
  echo "Tools ($tool_count):"
  if [[ $tool_count -eq 0 ]]; then
    echo "  (none)"
  else
    for tool_entry in "${TOOLS[@]}"; do
      local t_name="${tool_entry%%:*}"
      local t_target="${tool_entry#*:}"
      printf '  %-12s → %s\n' "$t_name" "$t_target"
    done
  fi
  echo ""

  local skill_count=${#SKILLS_REMOTE[@]}
  echo "Remote Skills ($skill_count):"
  if [[ $skill_count -eq 0 ]]; then
    echo "  (none)"
  else
    for skill_entry in "${SKILLS_REMOTE[@]}"; do
      local s_name s_type s_url s_path s_ref
      IFS='|' read -r s_name s_type s_url s_path s_ref <<< "$skill_entry"
      if [[ "$s_type" == "git" ]]; then
        printf '  %s (git, %s, ref: %s)\n' "$s_name" "$s_url" "$s_ref"
      else
        printf '  %s (local, %s)\n' "$s_name" "$s_path"
      fi
    done
  fi
  echo ""

  local file_count=${#FILES[@]}
  echo "Files ($file_count):"
  if [[ $file_count -eq 0 ]]; then
    echo "  (none)"
  else
    for file_entry in "${FILES[@]}"; do
      local f_dest f_type f_url f_path f_ref
      IFS='|' read -r f_dest f_type f_url f_path f_ref <<< "$file_entry"
      if [[ "$f_type" == "git" ]]; then
        printf '  %s ← git %s @ %s:%s\n' "$f_dest" "$f_url" "$f_ref" "$f_path"
      else
        printf '  %s ← %s\n' "$f_dest" "$f_path"
      fi
    done
  fi
  echo ""

  echo "Hooks:"
  if [[ ${#HOOKS_PRE_SYNC[@]} -eq 0 ]]; then
    printf '  pre_sync:  (none)\n'
  else
    local joined
    joined=$(printf '%s, ' "${HOOKS_PRE_SYNC[@]}")
    printf '  pre_sync:  %s\n' "${joined%, }"
  fi
  if [[ ${#HOOKS_POST_SYNC[@]} -eq 0 ]]; then
    printf '  post_sync: (none)\n'
  else
    local joined
    joined=$(printf '%s, ' "${HOOKS_POST_SYNC[@]}")
    printf '  post_sync: %s\n' "${joined%, }"
  fi
  echo ""

  echo "Features:"
  printf '  %-14s = %s\n' "enable_sync"   "${FEATURE_ENABLE_SYNC:-true}"
  printf '  %-14s = %s\n' "enable_create" "${FEATURE_ENABLE_CREATE:-true}"
}
