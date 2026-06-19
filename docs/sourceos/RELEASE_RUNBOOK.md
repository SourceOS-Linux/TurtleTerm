# TurtleTerm Release Runbook

Step-by-step instructions for cutting `turtle-term-v0.1.0` and setting up the public Homebrew tap.

## Prerequisites

- `gh` CLI authenticated as an admin of `SourceOS-Linux`
- Rust toolchain (`rustup show`)
- Homebrew installed
- `python3 -m pytest` available

---

## Step 1 — Confirm CI green

```bash
gh run list --repo SourceOS-Linux/TurtleTerm --limit 10
gh run view --repo SourceOS-Linux/TurtleTerm <run-id>
```

All jobs in `turtle-term-ci.yml` must pass:
- python-layer (ubuntu + macos)
- packaging
- trust-surface

The rust-check job may be `continue-on-error` — verify it at least starts.

---

## Step 2 — Run Python tests locally

```bash
cd ~/dev/TurtleTerm
pip install pytest
python3 -m pytest assets/sourceos/tests/ -v
```

Fix any failures before cutting the tag.

---

## Step 3 — Smoke-test the gateway and MCP server

```bash
echo '{"action":"ping"}' | python3 assets/sourceos/bin/turtle-agentd --stdio
python3 assets/sourceos/bin/turtle-agentctl --stdio ping
python3 assets/sourceos/bin/turtle-agentctl --stdio surfaces
python3 assets/sourceos/bin/turtle-agentctl --stdio noetica-status
python3 assets/sourceos/bin/turtle-language synapseiq-status
python3 assets/sourceos/bin/turtle-language diagnostics assets/sourceos/bin/turtle-agentd
python3 assets/sourceos/mcp/turtle-mcp-server <<'EOF'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"0"}}}
EOF
```

---

## Step 4 — Create SourceOS-Linux/homebrew-tap

```bash
gh repo create SourceOS-Linux/homebrew-tap \
  --public \
  --description "SourceOS-Linux Homebrew tap" \
  --clone

cd /tmp/homebrew-tap
cp ~/dev/TurtleTerm/packaging/homebrew/tap-scaffold/README.md .
mkdir -p Formula
# Do NOT copy the tap-scaffold formula yet — it has a FIXME sha256.
# Copy it after Step 6 when the real URL and sha256 are known.
git add .
git commit -m "init: SourceOS-Linux homebrew tap"
git push
```

---

## Step 5 — Cut the release tag

```bash
cd ~/dev/TurtleTerm

# Confirm you are on main with a clean tree.
git status
git log --oneline -5

# Create and push the tag.
git tag turtle-term-v0.1.0
git push origin turtle-term-v0.1.0
```

This triggers the release workflow if `.github/workflows/` contains a tag-triggered release job.
If not, proceed to Step 6 manually.

---

## Step 6 — Publish release artifacts

```bash
cd ~/dev/TurtleTerm

# Build macOS release binary (run on an Apple Silicon Mac).
cargo build --release --locked -p wezterm -p wezterm-gui -p wezterm-mux-server

# Package.
python3 packaging/scripts/write-turtle-term-manifest.py \
  --version 0.1.0 \
  --output /tmp/turtle-term-v0.1.0-macos-arm64/

# Create the tarball and compute sha256.
cd /tmp
tar czf turtle-term-v0.1.0-macos-arm64.tar.gz turtle-term-v0.1.0-macos-arm64/
sha256sum turtle-term-v0.1.0-macos-arm64.tar.gz

# Upload to the GitHub release.
gh release create turtle-term-v0.1.0 \
  --repo SourceOS-Linux/TurtleTerm \
  --title "TurtleTerm v0.1.0" \
  --notes "First TurtleTerm release." \
  turtle-term-v0.1.0-macos-arm64.tar.gz \
  turtle-term-v0.1.0-macos-arm64.tar.gz.sha256
```

---

## Step 7 — Update the tap formula with real sha256

```bash
# Get the real sha256 from Step 6 output.
REAL_SHA256="..."
REAL_URL="https://github.com/SourceOS-Linux/TurtleTerm/releases/download/turtle-term-v0.1.0/turtle-term-v0.1.0-macos-arm64.tar.gz"

# Copy tap-scaffold formula and fill in real values.
cp ~/dev/TurtleTerm/packaging/homebrew/tap-scaffold/Formula/turtle-term.rb \
   /tmp/homebrew-tap/Formula/turtle-term.rb

# Edit the FIXME lines.
sed -i "s|FIXME_replace_with_real_sha256_after_release|$REAL_SHA256|" \
  /tmp/homebrew-tap/Formula/turtle-term.rb
sed -i "s|FIXME.*tar.gz|$REAL_URL|" \
  /tmp/homebrew-tap/Formula/turtle-term.rb

cd /tmp/homebrew-tap
git add Formula/turtle-term.rb
git commit -m "formula: turtle-term v0.1.0"
git push
```

---

## Step 8 — Verify tap install

```bash
brew tap SourceOS-Linux/tap
brew install --HEAD SourceOS-Linux/tap/turtle-term  # HEAD while stable tarball is small
```

Or stable once the tarball is published:

```bash
brew install SourceOS-Linux/tap/turtle-term
```

Verify:

```bash
turtle-term paths
turtle-agentctl --stdio ping
turtle-agentctl --stdio noetica-status
turtle-language synapseiq-status
turtle-mcp-server  # Ctrl-C after MCP handshake
```

---

## Step 9 — Build and publish Homebrew bottles

```bash
# On macOS ARM64:
brew test-bot --only-cleanup-before
brew test-bot --only-setup
brew test-bot --only-tap-syntax SourceOS-Linux/tap
brew test-bot --only-formulae SourceOS-Linux/tap/turtle-term

# Upload bottles (requires bottle CI — see .github/workflows/homebrew-bottle.yml).
gh workflow run homebrew-bottle.yml --repo SourceOS-Linux/homebrew-tap
```

---

## Step 10 — Wire Claude Code MCP (post-install verification)

Add to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "turtleterm": {
      "type": "stdio",
      "command": "turtle-mcp-server"
    }
  }
}
```

Then in Claude Code:

```
/mcp
```

Confirm `turtleterm` is listed and tools are visible: `terminal_sessions`, `terminal_inspect`, `terminal_propose`, `language_diagnostics`, `noetica_query`, etc.

---

## Definition of done

- [ ] CI green on `SourceOS-Linux/TurtleTerm`
- [ ] `turtle-term-v0.1.0` tag pushed
- [ ] Release artifacts (tarball + sha256 + manifest + SBOM) published
- [ ] `SourceOS-Linux/homebrew-tap` exists with correct formula
- [ ] `brew install SourceOS-Linux/tap/turtle-term` succeeds on macOS
- [ ] `turtle-agentctl --stdio ping` returns `noetica_reachable: true/false`
- [ ] `turtle-mcp-server` responds to MCP `initialize`
- [ ] Claude Code lists TurtleTerm tools via `/mcp`
