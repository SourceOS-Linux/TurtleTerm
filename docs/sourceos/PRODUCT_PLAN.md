# SourceOS Terminal Workbench Product Plan

## Purpose

This fork turns WezTerm into the SourceOS Terminal Workbench substrate: a policy-aware, agent-addressable, workspace-native terminal fabric for SourceOS, AgentPlane, OpenCLAW, Matrix/AgentTerm, workstation contracts, and local/container/remote execution lanes.

WezTerm remains the terminal and multiplexer substrate. SourceOS adds the governance, session semantics, defaults, policy envelope, agent bridge, workspace identity, and packaging profile required for an agentic Linux workstation.

## Licensing posture

The upstream fork carries `LICENSE.md` under the MIT License. SourceOS-specific changes must preserve upstream copyright, attribution, license text, and bundled font license obligations.

Do not remove upstream identity or attribution. SourceOS branding should be layered as defaults, profiles, documentation, policy integrations, and optional feature flags.

## Product thesis

Most Linux terminals are desktop terminals. We need a terminal session fabric.

The strategic value of this fork is not cosmetic theming. The strategic value is that WezTerm already has the right primitives for an agentic workstation:

- GUI terminal surface
- local and remote multiplexing
- panes, tabs, windows, workspaces
- SSH support
- Unix-domain and mux-server components
- portable PTY layer
- Lua configuration and extension surface
- graphics protocol support
- CLI-oriented control model
- Rust workspace suitable for auditable system integration

SourceOS should build on those primitives and add policy-aware session control rather than handing agents raw shell access.

## Layering model

### 1. Terminal frontend

The visible terminal application. WezTerm is the canonical SourceOS agent terminal substrate.

KDE Konsole and GNOME Ptyxis may remain first-class native user terminals, but this fork is where SourceOS builds agent-addressable terminal fabric features.

### 2. Session fabric

The durable terminal/mux plane: windows, tabs, panes, workspaces, PTYs, local domains, remote domains, SSH domains, restore metadata, and attach/detach semantics.

### 3. SourceOS session contract

A structured contract describing each terminal session and each command lifecycle event.

Expected fields include:

- `sourceos.session_id`
- `sourceos.workspace_id`
- `sourceos.actor_id`
- `sourceos.policy_bundle_id`
- `sourceos.execution_domain`
- `pane_id`
- `tab_id`
- `window_id`
- `cwd`
- `repo_root`
- `git_branch`
- `host`
- `user`
- `container_id`
- `command`
- `exit_status`
- `started_at`
- `completed_at`
- `stdout_digest`
- `stderr_digest`
- `artifact_paths`
- `receipt_path`

### 4. Policy bridge

Agents should not receive ambient shell authority. All terminal actions must flow through scoped grants.

Grant modes:

- inspect session
- summarize session
- propose command
- execute command
- attach to pane
- create artifact
- open issue or pull request
- hand off to another agent

The policy bridge decides whether a proposed terminal action is allowed in the current execution domain.

### 5. Agent bridge

A local sidecar protocol for AgentPlane, OpenCLAW, Codex, Claude Code, local LLM routing, Matrix/AgentTerm, and future SourceOS agents.

The first implementation should be sidecar-first, not invasive. The terminal emits structured events. The sidecar consumes them, applies policy, and exposes safe control methods.

### 6. Workstation contracts and evidence

Terminal sessions should emit receipts compatible with SourceOS workstation contracts and conformance lanes.

Each command receipt should be independently auditable and should identify:

- who or what initiated the command
- where it ran
- what policy allowed it
- what command was executed
- what the result was
- what artifacts were produced
- how output can be replayed, summarized, or verified

## First alignment lanes

### Lane 1: SourceOS profile pack

Deliver a non-invasive default profile pack under `assets/sourceos/`.

Initial scope:

- SourceOS default Lua config
- workspace-aware tab titles
- sane pane/tab keybindings
- SourceOS color and font defaults without removing upstream themes
- visual execution-domain cues for host, container, SSH, and future microVM domains
- launcher profile conventions for SourceOS workspaces

Acceptance:

A SourceOS user can install the profile pack without rebuilding WezTerm and get a coherent terminal experience aligned with SourceOS desktop ergonomics.

### Lane 2: Session identity and receipts

Define the first terminal session contract and receipt format.

Initial scope:

- session identity model
- command lifecycle schema
- NDJSON event stream convention
- receipt file convention
- output digest convention
- workspace/repo/domain metadata convention

Acceptance:

A terminal session can produce structured events that another SourceOS component can consume without scraping terminal scrollback.

### Lane 3: Agent-safe terminal bridge

Add an opt-in local bridge for agents.

Initial scope:

- inspect-only mode
- summarize-session mode
- propose-command mode
- execute-command mode behind policy grants
- explicit actor identity on every request
- local-only default transport

Acceptance:

An agent can request context or propose a command without receiving unrestricted terminal authority.

### Lane 4: Container and remote execution awareness

Align terminal domains with SourceOS execution lanes.

Initial execution domains:

- host
- Podman container
- Distrobox/Toolbox
- SSH remote
- future microVM lane
- future layered VM/container lane

Acceptance:

A terminal pane can identify where it is running and the policy system can distinguish host execution from isolated execution.

### Lane 5: Matrix/AgentTerm integration

AgentTerm is the ChatOps layer. This fork is the terminal fabric.

Initial scope:

- session IDs that can be referenced from Matrix
- summaries consumable by Matrix rooms
- command receipts linkable from ChatOps
- policy-gated command requests from Matrix/AgentTerm

Acceptance:

A Matrix/AgentTerm operator can reference a terminal session, request a summary, inspect receipts, and route approved actions without taking raw shell control.

### Lane 6: Packaging and distro integration

Package SourceOS defaults without making the fork hard to rebase.

Initial scope:

- SourceOS config package
- Linux desktop profile package
- upstream sync policy
- changelog discipline
- build validation lane

Acceptance:

SourceOS can ship the terminal substrate while still being able to rebase from upstream WezTerm.

## Known gaps

- No SourceOS-specific product plan existed in the fork before this file.
- No SourceOS profile pack exists yet.
- No terminal session contract exists yet.
- No command receipt format exists yet.
- No agent bridge exists yet.
- No policy-fabric bridge exists yet.
- No workstation-contract integration exists yet.
- No Matrix/AgentTerm bridge exists yet.
- No KDE/GNOME terminal coexistence guidance exists yet.
- No upstream synchronization policy exists yet.
- No distinction exists between upstream-friendly patches and SourceOS-only patches.

## Upstream discipline

Keep the fork clean.

SourceOS-specific changes should be:

- opt-in
- namespaced
- documented
- isolated where practical
- compatible with future upstream rebases

Upstream-friendly bug fixes should be prepared so they can be submitted upstream.

Do not turn this fork into an unmaintainable hard fork unless there is a specific product reason and the tradeoff is documented.

## v0 acceptance standard

SourceOS Terminal Workbench is v0-ready when:

1. A user can launch the SourceOS terminal profile.
2. A terminal session receives a stable SourceOS session ID.
3. Commands can emit structured lifecycle events.
4. Receipts identify actor, workspace, repo, domain, policy, command, status, timestamps, digests, and artifacts.
5. An agent can inspect or summarize a session without raw shell control.
6. Agent command execution is blocked unless a SourceOS policy grant allows it.
7. Matrix/AgentTerm can reference session IDs and receipts.
8. The fork can still be rebased from upstream without fighting cosmetic divergence.
