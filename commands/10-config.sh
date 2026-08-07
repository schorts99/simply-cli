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

  cat > "$cfg_file" <<'EOF'
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

# Optional hooks to run after certain commands
[hooks]
# command to run after `simply sync` (string or array of strings)
post_sync = ["echo 'synced'"]

# Example feature toggles
[features]
enable_sync = true
enable_create = true

# Notes: use `simply config` to re-generate this file (it will back up existing files)
EOF

  log "✅ Created $cfg_file"
  log "Edit $cfg_file to customize project metadata, skills, and tool targets"
}
