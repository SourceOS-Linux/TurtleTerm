# TurtleTerm

> They say the world was built on the back of a turtle. TurtleTerm carries the shell on its back.

**The AI terminal that's faster than Warp, runs its AI fully local, and proves every agent action — then does all of Warp's tricks too.**

TurtleTerm is a WezTerm-based terminal with a full AI agent fabric built in: inline command autosuggest, a self-hosted co-pilot, governed autonomous task execution, workflow libraries, and live session sharing — none of it cloud-locked, none of it metered.

## Why TurtleTerm beats Warp

| | TurtleTerm | Warp |
|---|---|---|
| **Core speed** | WezTerm / WebGPU (faster) | ~8ms input latency |
| **AI backend** | Local (Ollama / Noetica) *or* Claude — your choice | Proprietary US cloud only |
| **Cost to use AI** | $0, self-hosted, no meter | $20/mo, 1,500 credits, or BYOK |
| **Telemetry** | None required | Must be ON to use AI on Free |
| **Inline autosuggest** | ✅ local ghost text (~1ms history path) | ✅ cloud |
| **Workflow library** | ✅ `turtle-drive`, versioned in *your* Gitea | ✅ Warp Drive (their cloud) |
| **Live session sharing** | ✅ self-hosted over WezTerm mux | ✅ their cloud |
| **Autonomous agent** | ✅ plan→execute→verify, **default-deny destructive** | ✅ agent mode |
| **Replayable, attestable agent runs** | ✅ `ReasoningRun/Event/Receipt/ReplayPlan`, sealed tamper-evident | ❌ nothing in this class |
| **Voice→shell · personas · AI coach · cost tracking** | ✅ | ❌ |
| **Remote multiplexing** | ✅ native, no remote tmux | ❌ |

Full honest head-to-head (our gaps included): [docs/COMPETITIVE.md](docs/COMPETITIVE.md).

## The arsenal (40+ commands)

- **`turtle-copilot`** — self-hosted AI co-pilot: error-explain, multi-turn chat, fix-memory recall, multi-backend (Claude / Ollama / Noetica)
- **`turtle-autonomous`** — governed plan→execute→verify agent; safe-by-default dry-run; emits replayable, sealable reasoning evidence
- **`turtle-drive`** — sovereign Warp Drive: parameterized workflows/runbooks, versioned in your own Gitea forge
- **`turtle-share`** — live session sharing over WezTerm mux; unix-socket / SSH, no cloud account
- **`turtle-gh` / `turtle-gitea`** — full `gh` CLI parity, Gitea-primary, with AI PR bodies + changelogs + review
- **`turtle-seal`** — seal reasoning receipts into externally-verifiable, tamper-evident evidence
- **`turtle-onboard`** guided first-run · **`turtle-diagnose`** health check · **`turtle-voice`** voice→shell · **`turtle-cost`** per-model AI spend
- MCP server (`turtle-mcp-server`) exposes the whole fabric to Claude Code.

TurtleTerm presents its own product surface: TurtleTerm launchers, TurtleTerm profile, TurtleTerm agent gateway, TurtleTerm release artifacts, and TurtleTerm skill manifests. Third-party notices and required license attribution are preserved in the repository license files and release artifacts.

## Install

Tapless Homebrew install from this repository:

```bash
brew install --HEAD https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/packaging/homebrew/Formula/turtle-term.rb
```

Preferred public Homebrew flow after the tap is published:

```bash
brew install SourceOS-Linux/tap/turtle-term
```

Current tap HEAD formula flow after the tap is published:

```bash
brew install --HEAD SourceOS-Linux/tap/turtle-term
```

Local checkout flow:

```bash
brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb
```

Direct release artifact installer after the first TurtleTerm release exists:

```bash
curl -fsSL https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/packaging/scripts/install-turtle-term.sh | bash
```

See `docs/sourceos/INSTALL.md` for full install, profile activation, and validation instructions.

## Launch

```bash
turtleterm
```

## Commands

```bash
turtle-term paths
turtle-term run -- echo hello
turtle-term office plan --title "Demo Report" --artifact-type document --format md
turtle-term /office plan --office-action convert --input ./demo.docx --to pdf
turtle-term office evidence inspect ./office-evidence.json
turtle-agentctl --stdio ping
turtle-tmux panes
```

`turtle-term` is the command wrapper. `turtleterm` is the graphical launcher. `sourceos-term` remains available for SourceOS contract compatibility.

The `office` / `/office` operator surface does not implement an office suite inside TurtleTerm. It produces SourceOS Office operator plans that point to `sourceosctl office`, records the receipt command to run through TurtleTerm, and summarizes `OfficeArtifactEvidence` runtime contract IDs when present.

## Product surfaces

- TurtleTerm graphical launcher
- TurtleTerm mux launcher
- TurtleTerm command wrapper
- TurtleTerm local agent gateway
- TurtleTerm agent CLI
- TurtleTerm tmux bridge
- TurtleTerm Office operator flow planning
- TurtleTerm skill manifests
- TurtleTerm turtle icon
- TurtleTerm release artifacts, manifests, SBOMs, and attestations

## License and notices

TurtleTerm is MIT licensed. Required third-party notices are preserved in `LICENSE.md` and release artifacts.