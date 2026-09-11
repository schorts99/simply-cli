cmd_update() {
  echo "Checking for updates..."
  echo "Current version: $SIMPLY_VERSION"

  # Read repository URL from project config (same sed pattern used in install.sh)
  local repo_url
  repo_url=$(sed -n 's/^[[:space:]]*repository *= *"\(.*\)".*/\1/p' \
    "${PROJECT_CONFIG_FILE:-.simply/config.toml}" 2>/dev/null | tr -d '\r' | tail -n 1)

  if [[ -z "$repo_url" ]]; then
    echo "ℹ️  No repository configured — set 'repository' in [project] config to enable update checks"
    return
  fi

  # Only GitHub repos are supported
  if [[ "$repo_url" != *"github.com"* ]]; then
    echo "ℹ️  No repository configured — set 'repository' in [project] config to enable update checks"
    return
  fi

  # Convert https://github.com/org/repo  →  https://api.github.com/repos/org/repo/releases/latest
  local api_url
  api_url=$(echo "$repo_url" | sed 's|https://github\.com/\([^/]*/[^/]*\).*|https://api.github.com/repos/\1/releases/latest|')

  # Pick a fetch tool
  local response
  if command -v curl >/dev/null 2>&1; then
    response=$(curl -fsSL "$api_url" 2>/dev/null) || {
      warn "Failed to reach $api_url — check your network connection"
      return
    }
  elif command -v wget >/dev/null 2>&1; then
    response=$(wget -q -O- "$api_url" 2>/dev/null) || {
      warn "Failed to reach $api_url — check your network connection"
      return
    }
  else
    warn "Neither curl nor wget is available — cannot check for updates"
    return
  fi

  # Parse tag_name from the JSON response (no jq needed)
  local latest
  latest=$(echo "$response" | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/' | head -1)

  if [[ -z "$latest" ]]; then
    warn "Could not parse latest release from GitHub API response"
    return
  fi

  if [[ "$latest" == "$SIMPLY_VERSION" ]]; then
    echo "✅ Already up to date ($SIMPLY_VERSION)"
  else
    log "Update available: $SIMPLY_VERSION → $latest"
    log "Re-run: bash install.sh"
  fi
}
