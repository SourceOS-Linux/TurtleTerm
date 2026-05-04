# TurtleTerm + SourceOS State Integrity Integration

Status: integration plan
Canonical spec: `SourceOS-Linux/sourceos-spec/docs/architecture/sourceos-state-integrity-layer.md`
Program tracker: `SourceOS-Linux/sourceos-spec#83`

## Purpose

TurtleTerm should be a first-class terminal-native surface for SourceOS State Integrity. The goal is not to make terminal sync noisy. The goal is to make local-first state, repo state, agent state, profile state, and repair state visible exactly when they matter.

## Required Terminal State

TurtleTerm should be able to surface:

- workspace state health
- repo/worktree state
- branch ahead/behind/diverged state
- agent-owned changes
- object conflict status
- offline/local-only mode
- transport failures
- policy blocks
- repair recommendations
- active profile
- active device
- active workspace

## Integration Contract

Initial integration should consume either CLI output or the future daemon API:

```bash
sourceos sync status --json
sourceos sync doctor --json
sourceos sync explain <object> --json
sourceos sync conflicts --json
sourceos sync profiles --json
sourceos sync devices --json
```

TurtleTerm should treat these as structured state contracts, not scraped log output.

## Status Surface

A minimal statusline/prompt integration should distinguish:

- clean
- degraded
- conflicted
- policy-blocked
- offline/local-only
- repair-recommended
- daemon-unavailable

These states must be visually distinct from ordinary Git dirty-state indicators. A repo can be clean while the workspace is policy-blocked, conflicted, or degraded.

## Command Routing

TurtleTerm should expose copy-pasteable diagnostic commands:

```bash
sourceos sync status
sourceos sync doctor
sourceos sync explain <object>
sourceos sync conflicts
sourceos sync repair --dry-run
```

Destructive repair/apply paths should not be hidden behind a casual prompt action.

## Agent and Neovim Workflow

TurtleTerm should cooperate with Neovim and agent workflows:

- identify agent-owned changes
- show draft/proposed/applied agent object transactions
- route patch review into editor flow
- surface policy warnings before agent changes are applied
- show local model/profile context where available

## Product Discipline

This must remain a TurtleTerm + SourceOS product surface. Avoid upstream terminal/product naming leakage. Avoid presenting this as generic file sync. The product concept is SourceOS state integrity and local continuity.

## Acceptance Criteria

- TurtleTerm has a documented State Integrity status surface.
- State output distinguishes policy-blocked, conflict, degraded, offline, and repair-needed states.
- Diagnostic commands route to `sourceos sync` rather than raw log scraping.
- The terminal surface can operate when offline and should not assume cloud availability.
