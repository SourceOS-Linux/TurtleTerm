# SourceOS Terminal Session Contract v0

## Purpose

This document defines the first SourceOS terminal session contract for the SourceOS WezTerm fork.

The contract exists so terminal sessions can be addressed by agents, Matrix/AgentTerm, PolicyFabric, workstation contracts, and replay/evidence tooling without giving any agent ambient shell authority.

This is a v0 contract. It is intentionally sidecar-friendly and does not require invasive terminal-core changes before the event and receipt model is validated.

## Design principles

1. The terminal remains the user's tool first.
2. Agents never receive unrestricted shell access.
3. Every terminal session has a stable identity.
4. Every agent-visible command event should be attributable, replayable, and policy-scoped.
5. Receipts should be useful even when full terminal scrollback is unavailable.
6. The contract should survive upstream rebases by remaining namespaced and opt-in.

## Identity model

### Session

A SourceOS terminal session is the durable unit that can be referenced by users, agents, Matrix rooms, and evidence tooling.

Required fields:

```json
{
  "schema": "sourceos.terminal.session.v0",
  "session_id": "sourceos-term-01J00000000000000000000000",
  "workspace_id": "sourceos-workspace-default",
  "created_at": "2026-05-02T00:00:00Z",
  "actor_id": "human:local-user",
  "frontend": "wezterm",
  "frontend_version": "unknown",
  "execution_domain": "host",
  "policy_bundle_id": "unbound"
}
```

### Window, tab, and pane

A session may contain many terminal surfaces.

```json
{
  "window_id": "wezterm-window-1",
  "tab_id": "wezterm-tab-1",
  "pane_id": "wezterm-pane-1",
  "title": "~/dev/sourceos",
  "cwd": "/home/user/dev/sourceos",
  "repo_root": "/home/user/dev/sourceos",
  "git_branch": "main",
  "host": "sourceos-laptop",
  "user": "user",
  "container_id": null
}
```

## Execution domains

`execution_domain` identifies where a command is running. This is a policy-critical field.

Initial values:

| Value | Meaning |
| --- | --- |
| `host` | Runs directly on the user's host system. |
| `podman` | Runs inside a Podman container. |
| `distrobox` | Runs inside Distrobox. |
| `toolbox` | Runs inside Toolbox. |
| `ssh` | Runs over SSH on a remote host. |
| `microvm` | Reserved for future microVM execution. |
| `layered-vm-container` | Reserved for future layered VM/container execution. |
| `unknown` | Domain could not be determined. |

Agents must treat `unknown` as higher risk than an explicitly isolated domain.

## Command lifecycle events

A command event describes a command observed or executed inside a terminal session.

### command.started

```json
{
  "schema": "sourceos.terminal.event.v0",
  "event_type": "command.started",
  "event_id": "evt_01J00000000000000000000000",
  "session_id": "sourceos-term-01J00000000000000000000000",
  "workspace_id": "sourceos-workspace-default",
  "window_id": "wezterm-window-1",
  "tab_id": "wezterm-tab-1",
  "pane_id": "wezterm-pane-1",
  "actor_id": "human:local-user",
  "policy_bundle_id": "policy:sourceos-local-dev",
  "execution_domain": "host",
  "cwd": "/home/user/dev/sourceos",
  "repo_root": "/home/user/dev/sourceos",
  "git_branch": "main",
  "host": "sourceos-laptop",
  "user": "user",
  "command": "cargo test",
  "started_at": "2026-05-02T00:00:00Z"
}
```

### command.completed

```json
{
  "schema": "sourceos.terminal.event.v0",
  "event_type": "command.completed",
  "event_id": "evt_01J00000000000000000000001",
  "session_id": "sourceos-term-01J00000000000000000000000",
  "workspace_id": "sourceos-workspace-default",
  "window_id": "wezterm-window-1",
  "tab_id": "wezterm-tab-1",
  "pane_id": "wezterm-pane-1",
  "actor_id": "human:local-user",
  "policy_bundle_id": "policy:sourceos-local-dev",
  "execution_domain": "host",
  "cwd": "/home/user/dev/sourceos",
  "repo_root": "/home/user/dev/sourceos",
  "git_branch": "main",
  "host": "sourceos-laptop",
  "user": "user",
  "command": "cargo test",
  "exit_status": 0,
  "started_at": "2026-05-02T00:00:00Z",
  "completed_at": "2026-05-02T00:00:20Z",
  "stdout_digest": "sha256:unknown",
  "stderr_digest": "sha256:unknown",
  "artifact_paths": [],
  "receipt_path": ".sourceos/terminal/receipts/evt_01J00000000000000000000001.json"
}
```

## Command receipt

A command receipt is the durable artifact emitted after command completion.

Minimum receipt shape:

```json
{
  "schema": "sourceos.terminal.receipt.v0",
  "receipt_id": "receipt_01J00000000000000000000000",
  "session_id": "sourceos-term-01J00000000000000000000000",
  "event_id": "evt_01J00000000000000000000001",
  "actor_id": "human:local-user",
  "requested_by": "human:local-user",
  "approved_by": "policy:sourceos-local-dev",
  "policy_bundle_id": "policy:sourceos-local-dev",
  "execution_domain": "host",
  "cwd": "/home/user/dev/sourceos",
  "repo_root": "/home/user/dev/sourceos",
  "git_branch": "main",
  "command": "cargo test",
  "exit_status": 0,
  "started_at": "2026-05-02T00:00:00Z",
  "completed_at": "2026-05-02T00:00:20Z",
  "stdout_digest": "sha256:unknown",
  "stderr_digest": "sha256:unknown",
  "artifacts": [],
  "replay": {
    "kind": "terminal-scrollback-pointer",
    "uri": "sourceos-terminal://sourceos-term-01J00000000000000000000000/events/evt_01J00000000000000000000001"
  }
}
```

## Agent grant model

Agents operate through explicit grants.

| Grant | Description | Default |
| --- | --- | --- |
| `terminal.inspect` | Read metadata and recent output. | Allowed only for trusted local agents. |
| `terminal.summarize` | Produce a summary from metadata/output. | Allowed only for trusted local agents. |
| `terminal.propose_command` | Propose a command without executing it. | Allowed. |
| `terminal.execute_command` | Execute a command in a pane/session. | Denied unless policy grants it. |
| `terminal.attach` | Attach to live interactive terminal control. | Denied by default. |
| `terminal.create_artifact` | Write a derived artifact from session output. | Denied unless scoped. |
| `terminal.open_pr` | Open a GitHub pull request from terminal state. | Denied unless repo policy grants it. |
| `terminal.handoff` | Hand off session context to another agent. | Denied unless target agent is registered and allowed. |

## Event transport

v0 event transport should be local and simple.

Recommended local path convention:

```text
$XDG_RUNTIME_DIR/sourceos/terminal/events.ndjson
```

Recommended receipt path convention:

```text
$XDG_STATE_HOME/sourceos/terminal/receipts/<session_id>/<event_id>.json
```

The transport should be append-only from the terminal/sidecar perspective. Policy and agent systems should consume the stream but not mutate historical events.

## Shell integration boundary

The terminal frontend should not be forced to infer all command boundaries by scraping output.

Preferred sources, in order:

1. SourceOS shell integration hooks.
2. WezTerm pane/session metadata.
3. Shell prompt markers.
4. Explicit `sourceos-term` wrapper commands.
5. Scrollback parsing only as a fallback.

## v0 non-goals

- Full terminal replay storage.
- Remote multi-user collaboration.
- Unrestricted agent terminal control.
- Hard dependency on Matrix.
- Hard dependency on one shell.
- Hard fork of WezTerm core before the sidecar model is validated.

## v0 acceptance

The contract is usable when a SourceOS terminal session can expose:

1. Stable session identity.
2. Workspace/repo/domain metadata.
3. Command start/completion events.
4. Command receipts.
5. Policy decision references.
6. Agent grants that distinguish inspection from execution.
7. A local event stream consumable by AgentPlane, AgentTerm, and workstation-contract tooling.
