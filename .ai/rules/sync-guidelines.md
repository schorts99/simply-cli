# Sync Guidelines

The `.ai/` folder is the canonical source for AI configuration.

Sync behavior:
- `.ai/AGENTS.md` is exported to shared target files:
  - Claude: `CLAUDE.md`
  - Copilot: `.github/copilot-instructions.md`
  - Codex: `AGENTS.md` (also syncs individual skills to `.agents/skills/`)
  - Antigravity: `ANTIGRAVITY.md`

- `.ai/rules/*.md` and `.ai/skills/` are exported to tool-specific directories:
  - Cursor: `.cursor/rules/*.mdc` and `.cursor/skills/*/SKILL.md` (with YAML frontmatter)
  - Claude: `.claude/rules/*.md` and `.claude/skills/*/SKILL.md`
  - Copilot: `.github/instructions/rules/*.instructions.md` and `.github/instructions/skills/` (with `applyTo: "**/*"` header)
  - Codex: Also receives individual skills at `.agents/skills/*.md` for native skill discovery
  - Antigravity: Receives combined `ANTIGRAVITY.md` with embedded index (no separate files)

- Each tool handles files according to its discovery mechanism:
  - Cursor, Claude, Copilot: Auto-discover individual `.md` files in dedicated directories
  - Codex: Uses combined `AGENTS.md` + auto-discovers skills in `.agents/skills/`
  - Antigravity: Only reads combined `ANTIGRAVITY.md` (no auto-discovery of separate files)

Keep each rule and skill file focused on a single responsibility.

