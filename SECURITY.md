# TurtleTerm Security Policy

## Scope

TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench for trusted command execution, terminal receipts, agent delegation, and reproducible operator workflows.

Security-sensitive areas include:

- terminal command execution
- `turtleterm`, `turtle-term`, and `sourceos-term` wrappers
- `turtle-agentd` local gateway
- `turtle-agentctl` command interface
- `turtle-tmux` bridge
- SourceOS terminal event and receipt generation
- release packaging and installer scripts
- Homebrew formulae and tap automation
- GitHub Actions release workflows
- artifact checksums, manifests, SBOMs, and attestations
- third-party notice and private runtime packaging boundaries
- trust-surface declaration and prove-clean behavior

## Supported versions

Before the first stable release, only `main` and tagged `turtle-term-v*` release candidates are supported.

After stable release begins, this file should be updated with a supported-version table.

## Trust surface baseline

TurtleTerm declares its current runtime authority in `TRUST_SURFACE.yaml`.

The default posture is:

- no external network egress by default;
- no non-loopback plaintext control channel;
- no credential storage by default;
- no inherited SSH agent by default;
- no browser/CDP/noVNC control by default;
- no containers by default;
- no persistent LaunchAgent until explicitly declared;
- no agent-delegated command execution without policy admission;
- terminal receipts, logs, traces, and status output must redact secrets.

Any pull request that expands local authority must update `TRUST_SURFACE.yaml` in the same change.

## Reporting a vulnerability

Do not open a public issue for a vulnerability.

Use GitHub private vulnerability reporting if available on this repository. If private reporting is not available, contact the repository maintainers directly and include:

- affected commit or release tag
- platform and install path
- reproduction steps
- expected behavior
- observed behavior
- impact assessment
- whether secrets, command execution, or user files are exposed

## Security expectations

TurtleTerm must not grant agents ambient shell authority.

Agent-facing terminal capabilities must be mediated through explicit SourceOS policy grants. Inspection, summarization, command proposal, command execution, attachment, artifact creation, pull request opening, and handoff should remain distinct grants.

Block changes that introduce any of the following without updating `TRUST_SURFACE.yaml`:

- LaunchAgent, LaunchDaemon, systemd unit, login item, scheduled task, or background service;
- local agent gateway listener, WebSocket, SSE, MCP, ACP, CDP, noVNC, dashboard, or browser relay;
- SSH-agent inheritance, API keys, OAuth tokens, model-provider tokens, keychain access, SecretRefs, or credential caches;
- host mounts, containers, Podman, Docker, Lima, VM, or local Kubernetes runtime;
- agent-delegated command execution or workspace-write behavior;
- shell, exec, spawn, tmux automation, or terminal control expansion;
- Homebrew, direct install, updater, plugin installer, or remote feature-flag authority;
- logs, receipts, traces, status output, or UI that may expose secrets.

## Required local commands

Before persistent services or local gateway listeners ship, TurtleTerm must provide:

```text
scripts/doctor
scripts/network-surface
scripts/credential-surface
scripts/policy-surface
scripts/purge
scripts/prove-clean
```

## Release security posture

Release artifacts should include:

- tarball
- SHA-256 checksum
- release manifest JSON
- SPDX JSON SBOM
- GitHub artifact attestations
- third-party notices

Release workflows should verify artifacts before publishing them.

## Runtime and notices

TurtleTerm presents TurtleTerm product commands and stores private terminal runtime files outside the public command path. Required third-party notices and license attribution are preserved in `LICENSE.md`, `THIRD_PARTY_NOTICES.md`, and release artifacts.

## Cleanup standard

Uninstall must remove authority, not just binaries.

The prove-clean target must verify no TurtleTerm process, launch item, listener, credential store, tmux bridge residue, state directory, config directory, cache, or log remains unless the user explicitly chooses to retain it.
