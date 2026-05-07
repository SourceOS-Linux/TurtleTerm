# TurtleTerm

> They say the world was built on the back of a turtle. TurtleTerm carries the shell on its back.

TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench for trusted command execution, terminal receipts, agent delegation, and reproducible operator workflows.

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
turtle-agentctl --stdio ping
turtle-agent-status --json
turtle-tmux panes
```

`turtle-term` is the command wrapper. `turtleterm` is the graphical launcher. `sourceos-term` remains available for SourceOS contract compatibility.

## Agent reliability status

`turtle-agent-status` is a read-only local operator view for SourceOS Agent Reliability evidence. It scans a workspace for local `.sourceos` artifacts and reports whether the agent lane is `ready`, `blocked`, `needs_review`, or has `no_artifacts`.

It reads:

- `.sourceos/logs/guardrail-decisions.jsonl`
- `StopGateArtifact` files named `stop-gate-artifact.json`
- `GuardedInvocationArtifact` files named `guarded-invocation-artifact.json`
- SocioSphere `AgentReliabilityGovernanceQueue` files matching `*governance-queue*.json`

Human-readable mode:

```bash
turtle-agent-status --root .
```

JSON mode:

```bash
turtle-agent-status --root . --json
```

The command is read-only. It does not modify policy, memory, git state, agent state, or governance queues.

## Product surfaces

- TurtleTerm graphical launcher
- TurtleTerm mux launcher
- TurtleTerm command wrapper
- TurtleTerm local agent gateway
- TurtleTerm agent CLI
- TurtleTerm agent reliability status CLI
- TurtleTerm tmux bridge
- TurtleTerm skill manifests
- TurtleTerm turtle icon
- TurtleTerm release artifacts, manifests, SBOMs, and attestations

## License and notices

TurtleTerm is MIT licensed. Required third-party notices are preserved in `LICENSE.md` and release artifacts.
