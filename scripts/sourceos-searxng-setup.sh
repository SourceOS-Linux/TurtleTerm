#!/usr/bin/env bash
# MIT License — https://sourceos.io
# sourceos-searxng-setup.sh — provision a sovereign SearXNG instance for TurtleTerm.
#
# Option A (preferred): Docker on 127.0.0.1:8888
# Option B (fallback):  Homebrew searxng on 127.0.0.1:8080
#
# Usage:
#   sourceos-searxng-setup.sh
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/sourceos"
STATE_FILE="$STATE_DIR/searxng-url"
CONTAINER_NAME="sourceos-searxng"
DOCKER_PORT="8888"
BREW_PORT="8080"

# ── helpers ────────────────────────────────────────────────────────────────────

log()  { echo "  [searxng] $*"; }
warn() { echo "  [searxng] WARN: $*" >&2; }

persist_url() {
  mkdir -p "$STATE_DIR"
  printf '%s' "$1" > "$STATE_FILE"
  log "URL persisted → $STATE_FILE"
}

test_instance() {
  local url="$1"
  local test_url="${url}/search?q=test&format=json"
  log "Testing $url ..."
  result=$(curl -sf --max-time 10 "$test_url" 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    warn "No response from $url — instance may need a moment to start."
    return 1
  fi
  count=$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(len(d.get('results',[])))" <<< "$result" 2>/dev/null || echo "?")
  log "SearXNG OK: ${count} results"
}

# ── Option A — Docker ──────────────────────────────────────────────────────────

setup_docker() {
  log "Docker available — using container path (port $DOCKER_PORT)."

  if docker inspect "$CONTAINER_NAME" &>/dev/null; then
    log "Container '$CONTAINER_NAME' already exists — starting if not running."
    docker start "$CONTAINER_NAME" &>/dev/null || true
  else
    log "Creating container '$CONTAINER_NAME' ..."
    docker run -d \
      --name "$CONTAINER_NAME" \
      --restart unless-stopped \
      -p "127.0.0.1:${DOCKER_PORT}:8080" \
      -e SEARXNG_BASE_URL="http://localhost:${DOCKER_PORT}" \
      -e SEARXNG_LIMITER=false \
      -e SEARXNG_SECRET_KEY="$(python3 -c 'import secrets; print(secrets.token_hex(32))')" \
      searxng/searxng:latest
    log "Container started."
  fi

  # Brief wait for the HTTP stack to bind
  sleep 3

  local url="http://localhost:${DOCKER_PORT}"
  test_instance "$url" || warn "Run 'docker logs $CONTAINER_NAME' if the instance stays unreachable."
  persist_url "$url"

  echo ""
  echo "  export SEARXNG_URL=http://localhost:${DOCKER_PORT}"
  echo ""
  log "Done (Docker). Add the export above to ~/.zshrc if desired."
}

# ── Option B — Homebrew ────────────────────────────────────────────────────────

setup_brew() {
  log "Docker not available — falling back to Homebrew."

  brew install searxng 2>/dev/null || true

  SEARXNG_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/searxng/settings.yml"
  if [[ ! -f "$SEARXNG_CFG" ]]; then
    mkdir -p "$(dirname "$SEARXNG_CFG")"
    cat > "$SEARXNG_CFG" <<YAML
use_default_settings: true
server:
  limiter: false
  secret_key: "$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
  port: ${BREW_PORT}
  bind_address: "127.0.0.1"
YAML
    log "Created $SEARXNG_CFG"
  else
    log "Using existing $SEARXNG_CFG"
  fi

  brew services restart searxng || brew services start searxng
  sleep 3

  local url="http://localhost:${BREW_PORT}"
  test_instance "$url" || warn "Check 'brew services info searxng' if the instance stays unreachable."
  persist_url "$url"

  echo ""
  echo "  export SEARXNG_URL=http://localhost:${BREW_PORT}"
  echo ""
  log "Done (Homebrew). Add the export above to ~/.zshrc if desired."
}

# ── main ───────────────────────────────────────────────────────────────────────

log "Provisioning sovereign SearXNG for TurtleTerm ..."

if docker info &>/dev/null 2>&1; then
  setup_docker
else
  setup_brew
fi
