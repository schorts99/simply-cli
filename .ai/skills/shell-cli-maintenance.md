# Shell CLI Maintenance Skill

When editing this repository, preserve these conventions:
- Use `set -euo pipefail` at the top of scripts.
- Quote variables consistently: `"$var"`.
- Use `local` in functions, avoid global variables when possible.
- Keep commands implemented as `cmd_<name>()` and dispatched via a `case` statement.
- Avoid external dependencies beyond standard POSIX utilities available on macOS and Linux.
- Back up modified generated outputs only when necessary; prefer editing `.ai/` source files.
