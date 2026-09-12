#!/bin/bash

set -euo pipefail

cmd_sync_ai_rules() {
  # default from project config (DRY_RUN), fallback to false
  local dry_run="${DRY_RUN:-false}"
  local refresh=false

  # CLI overrides
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --dry-run)    dry_run=true;  shift ;;
      --no-dry-run) dry_run=false; shift ;;
      --refresh)    refresh=true;  shift ;;
      *) break ;;
    esac
  done

  if [[ "$dry_run" == true ]]; then
    log "=== DRY RUN MODE ==="
  fi

  # Set up and prune cache
  local cache_dir=".simply/cache"
  if [[ "$dry_run" != true ]]; then
    mkdir -p "$cache_dir"
    _prune_cache "$cache_dir"
  fi

  # Run pre_sync hooks
  if [[ ${#HOOKS_PRE_SYNC[@]} -gt 0 ]]; then
    for hook_cmd in "${HOOKS_PRE_SYNC[@]}"; do
      log "Running pre_sync hook: $hook_cmd"
      eval "$hook_cmd"
    done
  fi

  log "Starting sync..."

  [[ -d "$AI_DIR" ]] || cmd_init_ai

  local rules_dir="${RULES_DIR:-$AI_DIR/rules}"
  local skills_dir="${SKILLS_DIR:-$AI_DIR/skills}"
  local main_file="$AI_DIR/AGENTS.md"

  # Materialise [[skills]] entries into $skills_dir before syncing tools
  if [[ ${#SKILLS_REMOTE[@]} -gt 0 ]]; then
    for skill_entry in "${SKILLS_REMOTE[@]}"; do
      # Format: name|type|url|path|ref
      local s_name s_type s_url s_path s_ref
      IFS='|' read -r s_name s_type s_url s_path s_ref <<< "$skill_entry"

      local s_dest_dir="$skills_dir/$s_name"

      if [[ "$s_type" == "git" ]]; then
        # Build a raw file URL for SKILL.md using the same host-detection
        # logic used for [[files]] entries below.
        local s_fetch_url
        local s_base
        s_base="${s_url%/}"   # strip trailing slash
        s_path="${s_path#/}"  # strip leading slash

        case "$s_base" in
          *github.com*)
            s_fetch_url="${s_base/github.com/raw.githubusercontent.com}/${s_ref}/${s_path}/SKILL.md"
            ;;
          *gitlab.com*|*gitlab.*)
            s_fetch_url="${s_base}/-/raw/${s_ref}/${s_path}/SKILL.md"
            ;;
          *)
            s_fetch_url="${s_base}/raw/${s_ref}/${s_path}/SKILL.md"
            ;;
        esac

        local s_cache_file="$cache_dir/skill-${s_name}.md"

        if [[ "$dry_run" == true ]]; then
          if [[ "$refresh" != true ]] && _cache_valid "$s_cache_file"; then
            log "[DRY-RUN] Would use cached skill $s_name → $s_dest_dir/SKILL.md"
          else
            log "[DRY-RUN] Would fetch skill (git) $s_fetch_url → $s_dest_dir/SKILL.md"
          fi
          continue
        fi

        if [[ "$refresh" != true ]] && _cache_valid "$s_cache_file"; then
          log "skill $s_name: using cache"
          mkdir -p "$s_dest_dir"
          cp "$s_cache_file" "$s_dest_dir/SKILL.md"
          continue
        fi

        local s_tmp
        s_tmp=$(mktemp)

        if command -v curl >/dev/null 2>&1; then
          if ! curl -fsSL "$s_fetch_url" -o "$s_tmp"; then
            warn "skills: failed to fetch $s_fetch_url — skipping $s_name"
            rm -f "$s_tmp"
            continue
          fi
        elif command -v wget >/dev/null 2>&1; then
          if ! wget -q "$s_fetch_url" -O "$s_tmp"; then
            warn "skills: failed to fetch $s_fetch_url — skipping $s_name"
            rm -f "$s_tmp"
            continue
          fi
        else
          warn "skills: curl or wget required for git type — skipping $s_name"
          rm -f "$s_tmp"
          continue
        fi

        mkdir -p "$s_dest_dir"
        cp "$s_tmp" "$s_cache_file"
        mv "$s_tmp" "$s_dest_dir/SKILL.md"
        log "skill (git) materialised → $s_dest_dir/SKILL.md"

      else
        # local type
        local s_src="${s_path%/}/SKILL.md"

        if [[ "$dry_run" == true ]]; then
          log "[DRY-RUN] Would copy skill (local) $s_src → $s_dest_dir/SKILL.md"
          continue
        fi

        if [[ ! -f "$s_src" ]]; then
          warn "skills: source not found, skipping → $s_src"
          continue
        fi

        mkdir -p "$s_dest_dir"
        cp "$s_src" "$s_dest_dir/SKILL.md"
        log "skill (local) materialised → $s_dest_dir/SKILL.md"
      fi
    done
  fi

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

        local f_basename f_cache_file
        f_basename=$(basename "$f_dest")
        f_cache_file="$cache_dir/file-${f_basename}.md"

        if [[ "$dry_run" == true ]]; then
          if [[ "$refresh" != true ]] && _cache_valid "$f_cache_file"; then
            log "[DRY-RUN] Would use cached file $f_basename → $f_dest"
          else
            log "[DRY-RUN] Would fetch (git) $f_fetch_url → $f_dest"
          fi
          continue
        fi

        if [[ "$refresh" != true ]] && _cache_valid "$f_cache_file"; then
          log "file $f_basename: using cache"
          mkdir -p "$(dirname "$f_dest")"
          backup_file "$f_dest"
          cp "$f_cache_file" "$f_dest"
          continue
        fi

        local tmp_file
        tmp_file=$(mktemp)

        if command -v curl >/dev/null 2>&1; then
          if ! curl -fsSL "$f_fetch_url" -o "$tmp_file"; then
            # Try authenticated fallback via gh CLI for private GitHub repos
            if command -v gh >/dev/null 2>&1 && [[ "$f_base" == *github.com* ]]; then
              # extract owner/repo from URL
              owner_repo=$(echo "$f_base" | sed -e 's#^https://##' -e 's#^http://##' -e 's#^git@##' -e 's#^www.##' -e 's#github.com/##' -e 's#\.git$##')
              # Use gh api to fetch file content (base64) and decode
              if content=$(gh api "repos/$owner_repo/contents/$f_path?ref=$f_ref" --jq '.content' 2>/dev/null); then
                # gh outputs null for binary; handle safely
                if [[ -n "$content" && "$content" != "null" ]]; then
                  printf "%s" "$content" | base64 --decode > "$tmp_file"
                else
                  warn "files: gh returned no content for $owner_repo/$f_path@$f_ref — skipping"
                  rm -f "$tmp_file"
                  continue
                fi
              else
                warn "files: gh api failed for $owner_repo/$f_path@$f_ref — skipping"
                rm -f "$tmp_file"
                continue
              fi
            else
              warn "files: failed to fetch $f_fetch_url — skipping"
              rm -f "$tmp_file"
              continue
            fi
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
        cp "$tmp_file" "$f_cache_file"
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

  # Run post_sync hooks
  if [[ ${#HOOKS_POST_SYNC[@]} -gt 0 ]]; then
    for hook_cmd in "${HOOKS_POST_SYNC[@]}"; do
      log "Running post_sync hook: $hook_cmd"
      eval "$hook_cmd"
    done
  fi
}

