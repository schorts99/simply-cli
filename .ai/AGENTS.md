# Project AI Instructions

## Core Philosophy
- Keep the CLI lightweight, reliable, and POSIX-compatible.
- Treat `.ai/` as source of truth; do not edit generated output files directly.
- Preserve shell script conventions used across `install.sh` and `commands/*.sh`.

## Project overview
This repository implements a minimal shell CLI named `simply` that:
- installs itself to `~/.local/bin`
- copies `commands/` and `resources/design-doc.md` into `~/.simply`
- initializes and syncs AI configuration files under `.ai/`
- supports `init`, `sync`, `status`, `doctor`, `create`, `uninstall`, and `version`

## `.ai` workflow
- Add or update `.ai/rules/*.md` for general AI guidance and tool-specific rule exports.
- Add or update `.ai/skills/*.md` for assistant skill definitions and behavior guidance.
- Keep `.ai/AGENTS.md` as the shared project-level instruction header.
- Run `simply sync ai [--dry-run]` to generate target files for supported tools.

## Tool export behavior
- `cursor` exports `.ai/rules` and `.ai/skills` with YAML frontmatter.
- `copilot` exports rules/skills with `applyTo: "**/*"` and writes `.github/copilot-instructions.md`.
- `claude` exports raw `.ai/AGENTS.md`, plus `.ai/rules` and `.ai/skills` content.
- `gemini` and `codex` export a combined file with `AGENTS.md` content plus an index of `.ai` sources.

## Maintainability notes
- Follow existing command structure: `cmd_<name>()` functions and top-level `case` dispatch.
- Preserve `set -euo pipefail` and safe quoting inside shell scripts.
- Keep `.ai` content concise and explicit so AI tools can add, improve, or fix scripts safely.
