# Simply CLI

Simply CLI is a lightweight shell-based tool for bootstrapping, managing, and syncing AI configuration files across projects. It installs a `simply` command to `~/.local/bin` and manages a local `~/.simply` copy of the repository, plus your AI configuration under `.ai/`.

## Features

- Install or upgrade the CLI with a single script
- Generate a project-level config file (`.simply/config.toml`) for per-project customization
- Initialize a `.ai/` folder structure for AI tooling
- Create a personalized `design-doc.md` from a local template
- Sync `.ai/` content (rules, skills, `AGENTS.md`) to multiple AI tool formats simultaneously
- Show current AI config status and configured tool targets
- Run a diagnostic `doctor` command to verify your environment
- Uninstall cleanly when done

## Installation

```bash
bash install.sh
```

This script will:

- Install `simply` to `~/.local/bin`
- Copy the `commands/` directory to `~/.simply/commands`
- Copy `resources/design-doc.md` to `~/.simply/design-doc.md` (personalized with your git author info)
- Create a global config at `~/.simply/config` for tool overrides
- Add `~/.local/bin` to `PATH` in your shell rc file
- Install shell completion for Bash or Zsh

> **Note:** Make sure to open a new terminal or `source` your shell rc file after installing.

## Usage

```bash
simply <command> [options]
```

### Commands

| Command | Description |
|---|---|
| `simply init ai` | Initialize `.ai/` with `rules/`, `skills/`, and `AGENTS.md` |
| `simply config` | Create `.simply/config.toml` in the current project |
| `simply create design-doc` | Copy the design-doc template from `~/.simply` into the current directory |
| `simply sync ai [--dry-run\|--no-dry-run]` | Sync `.ai/` content to all configured tool targets |
| `simply status` | Show `.ai/` status, file counts, and configured tools |
| `simply doctor` | Check `PATH`, verify tool targets, and report config status |
| `simply update` | Check for updates (placeholder for future support) |
| `simply uninstall` | Remove installed CLI files and clean up `~/.simply` |
| `simply version` | Show the installed Simply CLI version |
| `simply help` | Show usage information |

## Configuration

Simply supports two levels of configuration:

### Global config — `~/.simply/config`

Sourced as Bash on every `simply` invocation. Override the default `TOOLS` array to change which AI tools are synced globally:

```bash
TOOLS=(
  "cursor:.cursor"
  "claude:.claude"
  "copilot:.github"
  "antigravity:ANTIGRAVITY.md"
  "codex:AGENTS.md"
)
```

### Project config — `.simply/config.toml`

Run `simply config` to scaffold a `config.toml` in the current project. Overrides applied here take precedence over the global config:

```toml
[settings]
ai_dir    = ".ai"
rules_dir = ".ai/rules"
skills_dir = ".ai/skills"
dry_run   = true
backup_existing = true

[tools]
cursor      = ".cursor"
claude      = ".claude"
copilot     = ".github"
antigravity = "ANTIGRAVITY.md"
codex       = "AGENTS.md"
```

**Config precedence (lowest → highest):**
1. Built-in defaults
2. Global config (`~/.simply/config`) — Bash format
3. Project config (`.simply/config.toml`) — TOML format

## AI Workflow

1. **Install** — `bash install.sh`
2. **Init** — `simply init ai` to create the `.ai/` project structure
3. **Author** — add and edit Markdown files under `.ai/rules/` and `.ai/skills/`
4. **Preview** — `simply sync ai --dry-run` to preview what would be written
5. **Sync** — `simply sync ai --no-dry-run` to export files to all configured tools
6. **Verify** — `simply status` and `simply doctor` to confirm the environment

> `.ai/` is the source of truth. Do not edit synced output files directly.

## `.ai/` Structure

```
.ai/
├── AGENTS.md           # Shared project-level AI instructions (exported to all tools)
├── rules/
│   └── *.md            # Individual rule files (one responsibility per file)
└── skills/
    └── skill-name/
        ├── SKILL.md    # Skill definition and instructions
        └── scripts/    # Optional helper scripts
```

## Sync Output by Tool

| Tool | `AGENTS.md` target | Rules target | Skills target |
|---|---|---|---|
| **Cursor** | — | `.cursor/rules/*.mdc` (YAML frontmatter) | `.cursor/skills/*.mdc` (YAML frontmatter) |
| **Claude** | `CLAUDE.md` | `.claude/rules/*.md` | `.claude/skills/*.md` |
| **Copilot** | `.github/copilot-instructions.md` | `.github/instructions/rules/*.instructions.md` | `.github/instructions/skills/*.instructions.md` |
| **Antigravity** | Combined `ANTIGRAVITY.md` (with embedded index) | — (included in combined file) | — (included in combined file) |
| **Codex** | `AGENTS.md` (with embedded index) | — (included in combined file) | `.agents/skills/*.md` |

Custom tools can also be added to the `[tools]` config; if the target ends in `.md`, a combined file is produced. Otherwise a directory layout with `rules/` and `skills/` subdirectories is used.

## Make Targets

| Target | Description |
|---|---|
| `make install` | Install/upgrade the CLI |
| `make ai-init` | Run `simply init ai` |
| `make ai-create-design-doc` | Run `simply create design-doc` |
| `make ai-sync` | Run `simply sync ai rules` (project) |
| `make ai-sync-global` | Run `simply sync ai rules --global` |
| `make ai-sync-both` | Run `simply sync ai rules --both` |
| `make ai-status` | Run `simply status` |
| `make ai-doctor` | Run `simply doctor` |

## Repository Layout

```
Simply CLI/
├── install.sh          # Installer — sets up simply, PATH, and shell completion
├── Makefile            # Convenience targets for install and AI workflows
├── commands/           # Individual command implementations sourced by simply
│   ├── 00-utils.sh     # Shared helpers: logging, backup, sync primitives
│   ├── 01-init.sh      # simply init ai
│   ├── 02-create.sh    # simply create design-doc
│   ├── 03-sync.sh      # simply sync ai
│   ├── 04-status.sh    # simply status
│   ├── 05-doctor.sh    # simply doctor
│   ├── 06-update.sh    # simply update
│   ├── 07-uninstall.sh # simply uninstall
│   ├── 08-version.sh   # simply version
│   ├── 09-help.sh      # simply help
│   └── 10-config.sh    # simply config
├── resources/
│   └── design-doc.md   # Design doc template (personalized on install)
└── .ai/                # AI configuration source of truth
    ├── AGENTS.md
    ├── rules/
    └── skills/
```

## Notes

- `simply` is installed to `~/.local/bin/simply`
- `install.sh` targets macOS and Linux
- Existing synced files are backed up (timestamped `.bak`) before overwriting unless `backup_existing = false`
- `simply update` is a placeholder for future update support
