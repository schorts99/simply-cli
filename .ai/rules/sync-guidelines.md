# Sync Guidelines

The `.ai/` folder is the canonical source for AI configuration.

Sync behavior:
- `.ai/AGENTS.md` is copied into shared target files for Claude, Copilot, Gemini, and Codex.
- `.ai/rules/*.md` and `.ai/skills/*.md` are exported to tool-specific directories.
- Cursor adds a YAML frontmatter separator to every exported file.
- Copilot adds an `applyTo: "**/*"` header for rule files.
- Gemini and Codex receive a combined document with references to `.ai` sources.

Keep each rule and skill file focused on a single responsibility.
