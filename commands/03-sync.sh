#!/bin/bash

set -euo pipefail

cmd_sync_ai_rules() {
  # default from project config (DRY_RUN), fallback to true
  local dry_run="${DRY_RUN:-true}"

  # CLI overrides
  if [[ "${1:-}" == "--dry-run" ]]; then
    dry_run=true
    shift
  elif [[ "${1:-}" == "--no-dry-run" ]]; then
    dry_run=false
    shift
  fi

  if [[ "$dry_run" == true ]]; then
    log "=== DRY RUN MODE ==="
  fi

  log "Starting sync..."

  [[ -d "$AI_DIR" ]] || cmd_init_ai

  local rules_dir="${RULES_DIR:-$AI_DIR/rules}"
  local skills_dir="${SKILLS_DIR:-$AI_DIR/skills}"
  local main_file="$AI_DIR/AGENTS.md"

  for tool_entry in "${TOOLS[@]}"; do
    local tool="${tool_entry%%:*}"
    local target="${tool_entry#*:}"

    case "$tool" in
      cursor)
        sync_directory \
          cursor \
          rules \
          "$target/rules" \
          "$rules_dir" \
          ".mdc" \
          "$dry_run"

        sync_directory \
          cursor \
          skills \
          "$target/skills" \
          "$skills_dir" \
          ".mdc" \
          "$dry_run"
        ;;

      claude)
        local main_dest sub_dir
        if [[ "$target" == *.md ]]; then
          main_dest="$target"
          sub_dir="$(dirname "$target")"
        elif [[ "$target" == ".claude" ]]; then
          main_dest="CLAUDE.md"
          sub_dir="$target"
        else
          main_dest="$target/CLAUDE.md"
          sub_dir="$target"
        fi

        sync_single_file \
          claude \
          "$main_dest" \
          "$(cat "$main_file" 2>/dev/null || true)" \
          "$dry_run"

        sync_directory \
          claude \
          rules \
          "$sub_dir/rules" \
          "$rules_dir" \
          ".md" \
          "$dry_run"

        sync_directory \
          claude \
          skills \
          "$sub_dir/skills" \
          "$skills_dir" \
          ".md" \
          "$dry_run"
        ;;

      copilot)
        local main_dest sub_dir
        if [[ "$target" == *.md ]]; then
          main_dest="$target"
          sub_dir="$(dirname "$target")"
        else
          main_dest="$target/copilot-instructions.md"
          sub_dir="$target"
        fi

        sync_single_file \
          copilot \
          "$main_dest" \
          "$(cat "$main_file" 2>/dev/null || true)" \
          "$dry_run"

        sync_directory \
          copilot \
          rules \
          "$sub_dir/instructions/rules" \
          "$rules_dir" \
          ".instructions.md" \
          "$dry_run"

        sync_directory \
          copilot \
          skills \
          "$sub_dir/instructions/skills" \
          "$skills_dir" \
          ".instructions.md" \
          "$dry_run"
        ;;

      antigravity)
        local content

        content=$(cat "$main_file" 2>/dev/null || true)

        content+=$'\n\n'
        content+="$(build_directory_index \
          "Rules" \
          "$rules_dir" \
          "$tool")"

        content+=$'\n\n'
        content+="$(build_directory_index \
          "Skills" \
          "$skills_dir" \
          "$tool")"

        sync_single_file \
          "$tool" \
          "$target" \
          "$content" \
          "$dry_run"
        ;;

      codex)
        local content main_dest skills_target

        if [[ "$target" == *.md ]]; then
          main_dest="$target"
          skills_target="$(dirname "$target")/.agents/skills"
        else
          main_dest="$target/AGENTS.md"
          skills_target="$target/skills"
        fi

        content=$(cat "$main_file" 2>/dev/null || true)

        content+=$'\n\n'
        content+="$(build_directory_index \
          "Rules" \
          "$rules_dir" \
          "$tool")"

        content+=$'\n\n'
        content+="$(build_directory_index \
          "Skills" \
          "$skills_dir" \
          "$tool")"

        sync_single_file \
          "$tool" \
          "$main_dest" \
          "$content" \
          "$dry_run"

        sync_directory \
          codex \
          skills \
          "$skills_target" \
          "$skills_dir" \
          ".md" \
          "$dry_run"
        ;;

      *)
        # Generic / Custom tool fallback using configured target
        if [[ "$target" == *.md ]]; then
          local content
          content=$(cat "$main_file" 2>/dev/null || true)
          content+=$'\n\n'
          content+="$(build_directory_index "Rules" "$rules_dir" "$tool")"
          content+=$'\n\n'
          content+="$(build_directory_index "Skills" "$skills_dir" "$tool")"

          sync_single_file "$tool" "$target" "$content" "$dry_run"
        else
          sync_single_file "$tool" "$target/README.md" "$(cat "$main_file" 2>/dev/null || true)" "$dry_run"

          sync_directory "$tool" rules "$target/rules" "$rules_dir" ".md" "$dry_run"
          sync_directory "$tool" skills "$target/skills" "$skills_dir" ".md" "$dry_run"
        fi
        ;;
    esac
  done

  # Sync [[files]] entries (local or git)
  if [[ ${#FILES[@]} -gt 0 ]]; then
    for file_entry in "${FILES[@]}"; do
      # Format: dest|type|url|path|ref
      local f_dest f_type f_url f_path f_ref
      IFS='|' read -r f_dest f_type f_url f_path f_ref <<< "$file_entry"

      if [[ "$f_type" == "git" ]]; then
        # Build a raw file URL from the git repo URL + ref + path.
        # Supports github.com, gitlab.com, and Gitea/Forgejo instances.
        local f_fetch_url
        local f_base
        f_base="${f_url%/}"  # strip trailing slash
        f_path="${f_path#/}" # strip leading slash

        case "$f_base" in
          *github.com*)
            # https://github.com/org/repo -> https://raw.githubusercontent.com/org/repo/ref/path
            f_fetch_url="${f_base/github.com/raw.githubusercontent.com}/${f_ref}/${f_path}"
            ;;
          *gitlab.com*|*gitlab.*)
            # https://gitlab.com/org/repo -> https://gitlab.com/org/repo/-/raw/ref/path
            f_fetch_url="${f_base}/-/raw/${f_ref}/${f_path}"
            ;;
          *)
            # Gitea/Forgejo: https://host/org/repo -> https://host/org/repo/raw/branch/path
            f_fetch_url="${f_base}/raw/${f_ref}/${f_path}"
            ;;
        esac

        if [[ "$dry_run" == true ]]; then
          log "[DRY-RUN] Would fetch (git) $f_fetch_url → $f_dest"
          continue
        fi

        local tmp_file
        tmp_file=$(mktemp)

        if command -v curl >/dev/null 2>&1; then
          if ! curl -fsSL "$f_fetch_url" -o "$tmp_file"; then
            warn "files: failed to fetch $f_fetch_url — skipping"
            rm -f "$tmp_file"
            continue
          fi
        elif command -v wget >/dev/null 2>&1; then
          if ! wget -q "$f_fetch_url" -O "$tmp_file"; then
            warn "files: failed to fetch $f_fetch_url — skipping"
            rm -f "$tmp_file"
            continue
          fi
        else
          warn "files: curl or wget required for git type — skipping $f_dest"
          rm -f "$tmp_file"
          continue
        fi

        mkdir -p "$(dirname "$f_dest")"
        backup_file "$f_dest"
        mv "$tmp_file" "$f_dest"
        log "file (git) synced → $f_dest"

      else
        # local type
        if [[ "$dry_run" == true ]]; then
          log "[DRY-RUN] Would sync file $f_path → $f_dest"
          continue
        fi

        if [[ ! -f "$f_path" ]]; then
          warn "files: source not found, skipping → $f_path"
          continue
        fi

        mkdir -p "$(dirname "$f_dest")"
        backup_file "$f_dest"
        cp "$f_path" "$f_dest"
        log "file synced → $f_dest"
      fi
    done
  fi

  log "✅ Sync completed"
}

