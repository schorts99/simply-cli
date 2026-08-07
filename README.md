# Simply CLI

Simply CLI is a lightweight shell-based helper for bootstrapping, managing, and syncing AI-related project files. It installs a small `simply` command into `~/.local/bin` and manages a local `~/.simply` copy of the repository plus AI configuration under `.ai/`.

## Features

- Install or upgrade the CLI with a single script
- Initialize `.ai/` folder structure for AI tooling
- Create a personalized `design-doc.md` from a local template
- Sync AI configuration files to various tool formats
- Check current AI config status
- Run a simple diagnostic doctor command
- Uninstall cleanly when done

## Installation

```bash
bash install.sh
```

This script will:

- install `simply` to `~/.local/bin`
- copy the repository `commands/` directory to `~/.simply/commands`
- copy `resources/design-doc.md` to `~/.simply/design-doc.md`
- create optional shell completion support for Zsh

> Make sure `~/.local/bin` is in your `PATH`.

## Usage

```bash
simply <command> [options]
```

### Commands

- `simply init ai`
  - Initialize `.ai/` with `rules/`, `skills/`, and `AGENTS.md`
- `simply create design-doc`
  - Copy the generated `design-doc.md` template from `~/.simply` into the current directory
- `simply sync ai [--dry-run]`
  - Sync `.ai/` content to tool-specific target files
- `simply status`
  - Show the current `.ai/` status and file counts
- `simply doctor`
  - Run diagnostics, check `PATH`, and report config status
- `simply update`
  - Stub for update checking
- `simply uninstall`
  - Remove installed CLI files and cleanup `~/.simply`
- `simply version`
  - Show the installed Simply CLI version
- `simply help`
  - Show usage information

## Make Targets

The repository includes a `Makefile` with convenient targets:

- `make install` — install the CLI
- `make ai-init` — run `simply init ai`
- `make ai-create-design-doc` — run `simply create design-doc`
- `make ai-sync` — run `simply sync ai rules`
- `make ai-sync-global` — run `simply sync ai rules --global`
- `make ai-sync-both` — run `simply sync ai rules --both`
- `make ai-status` — run `simply status`
- `make ai-doctor` — run `simply doctor`

## AI Workflow

1. Install the CLI
2. Run `simply init ai` to create the `.ai/` project structure
3. Add and edit rule/skill markdown files under `.ai/rules/` and `.ai/skills/`
4. Run `simply sync ai` to export synced versions for supported tools
5. Use `simply status` and `simply doctor` to verify the environment

## Repository Layout

- `install.sh` — installer/extender for the CLI
- `Makefile` — convenience targets for install and AI workflows
- `commands/` — individual command implementations sourced by `simply`
- `resources/design-doc.md` — design doc template copied on install

## Notes

- `simply` is installed to `~/.local/bin/simply`
- The `install.sh` script currently targets macOS and Linux
- `simply update` is a placeholder for future update support
