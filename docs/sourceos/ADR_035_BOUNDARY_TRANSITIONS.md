# TurtleTerm ADR-035 Boundary Transitions and System-Action Transcript

## Decision

TurtleTerm adopts the `prophet-platform` ADR-035 transparent fault attribution contract family.
All system-level actions that cross a process, filesystem, or network boundary emit a typed
`BoundaryTransition` record. Faults are attributed via `FaultEnvelope`. Engine identity is
declared via `EngineManifest`. These records are consumed by sourceos-syncd, agentplane, and
the TurtleTerm operator console.

## Scope (issue TurtleTerm #17)

This document covers TurtleTerm's binding to ADR-035 for:

1. PTY spawn (`process-spawn` boundary)
2. File access for configuration / lua scripts / fonts (`file-read` boundary)
3. Network access for SSH and MUX connections (`network-fetch` boundary)
4. GPU/compositor surface allocation (`render-emit` boundary)
5. Clipboard read/write (`clipboard-read` / `clipboard-write` boundaries)

## EngineManifest — TurtleTerm

```json
{
  "id": "urn:srcos:engine-manifest:turtleterm:2026",
  "specVersion": "0.1.0",
  "engineKind": "terminal-helper",
  "engineId": "turtleterm",
  "version": "20241230-1",
  "declaredBoundaries": [
    "process-spawn",
    "file-read",
    "network-fetch",
    "render-emit",
    "clipboard-read",
    "clipboard-write"
  ],
  "allowedInputKinds": [
    "text/x-shellcommand",
    "text/x-luascript",
    "application/x-ssh-config"
  ],
  "sideEffectPolicy": "allowed-with-receipt",
  "networkEgressPolicy": "policy-gated",
  "sandboxKind": "ambient-user-session",
  "capabilityContractRef": "urn:srcos:capability-contract:turtleterm:2026",
  "orgPolicyRef": "urn:srcos:org-policy:default:2026"
}
```

## BoundaryTransition Fixtures

### PTY spawn (process-spawn, admitted)

```json
{
  "id": "urn:srcos:boundary-transition:turtleterm:pty-spawn-20260718T120000Z",
  "specVersion": "0.1.0",
  "engineRef": "urn:srcos:engine-manifest:turtleterm:2026",
  "boundaryKind": "process-spawn",
  "direction": "egress",
  "decision": "admitted",
  "policyDecisionRef": "urn:srcos:policy-decision:turtleterm-pty-spawn-admit-20260718",
  "commandToken": "bash",
  "argsRedacted": true,
  "observedAt": "2026-07-18T12:00:00Z"
}
```

### SSH connect (network-fetch, policy-gated — admitted)

```json
{
  "id": "urn:srcos:boundary-transition:turtleterm:ssh-20260718T120100Z",
  "specVersion": "0.1.0",
  "engineRef": "urn:srcos:engine-manifest:turtleterm:2026",
  "boundaryKind": "network-fetch",
  "direction": "egress",
  "decision": "admitted",
  "policyDecisionRef": "urn:srcos:policy-decision:turtleterm-ssh-admit-20260718",
  "targetOriginRedacted": true,
  "observedAt": "2026-07-18T12:01:00Z"
}
```

### Lua script file-read (file-read, admitted)

```json
{
  "id": "urn:srcos:boundary-transition:turtleterm:lua-file-read-20260718T120200Z",
  "specVersion": "0.1.0",
  "engineRef": "urn:srcos:engine-manifest:turtleterm:2026",
  "boundaryKind": "file-read",
  "direction": "ingress",
  "decision": "admitted",
  "policyDecisionRef": "urn:srcos:policy-decision:turtleterm-lua-read-admit-20260718",
  "pathRedacted": true,
  "observedAt": "2026-07-18T12:02:00Z"
}
```

### Clipboard write (clipboard-write, suppressed — org policy)

```json
{
  "id": "urn:srcos:boundary-transition:turtleterm:clipboard-write-20260718T120300Z",
  "specVersion": "0.1.0",
  "engineRef": "urn:srcos:engine-manifest:turtleterm:2026",
  "boundaryKind": "clipboard-write",
  "direction": "egress",
  "decision": "suppressed",
  "suppressionReason": "org policy: clipboard-write denied in restricted session",
  "policyDecisionRef": "urn:srcos:policy-decision:turtleterm-clipboard-deny-20260718",
  "observedAt": "2026-07-18T12:03:00Z"
}
```

## FaultEnvelope Fixtures

### PTY spawn failure (non-fatal — fallback to degraded mode)

```json
{
  "id": "urn:srcos:fault-envelope:turtleterm:pty-spawn-fail-20260718T130000Z",
  "specVersion": "0.1.0",
  "engineRef": "urn:srcos:engine-manifest:turtleterm:2026",
  "faultClass": "render-failure",
  "severity": "non-fatal",
  "boundaryTransitionRef": "urn:srcos:boundary-transition:turtleterm:pty-spawn-fail-20260718T130000Z",
  "recoveryAction": "emit-receipt-and-exit",
  "recoveryOutcome": "succeeded",
  "humanReviewRequired": false,
  "observedAt": "2026-07-18T13:00:00Z",
  "note": "PTY spawn failed (shell not found); TurtleTerm emitted a terminal receipt and displayed error pane."
}
```

### SSH policy violation (fatal)

```json
{
  "id": "urn:srcos:fault-envelope:turtleterm:ssh-policy-violation-20260718T140000Z",
  "specVersion": "0.1.0",
  "engineRef": "urn:srcos:engine-manifest:turtleterm:2026",
  "faultClass": "policy-violation",
  "severity": "fatal",
  "boundaryTransitionRef": "urn:srcos:boundary-transition:turtleterm:ssh-denied-20260718T140000Z",
  "policyDecisionRef": "urn:srcos:policy-decision:turtleterm-ssh-deny-20260718",
  "recoveryAction": "refuse-start",
  "recoveryOutcome": "succeeded",
  "humanReviewRequired": true,
  "humanReviewRef": "urn:srcos:review-request:turtleterm-ssh-policy-20260718",
  "observedAt": "2026-07-18T14:00:00Z",
  "note": "Org policy denied SSH connection to non-allowlisted host. Session terminated. Human review queued."
}
```

## System-Action Transcript Integration

TurtleTerm emits a machine-readable `system-action-transcript.jsonl` alongside each terminal
session. Each line is a `BoundaryTransition` or `FaultEnvelope` JSON object. The transcript is:

- Written to `~/.local/share/turtleterm/transcripts/<session-id>.jsonl`
- Consumed by `sourceos-syncd` for state integrity tracking
- Forwarded to `agentplane` when a governed agent session is active
- Never contains raw PTY content, credentials, or clipboard payloads

### Transcript line ordering

```
EngineManifest (once, at session start)
BoundaryTransition[process-spawn] (for each PTY spawn)
BoundaryTransition[file-read]* (for config/lua/font loads)
BoundaryTransition[network-fetch]* (for SSH/MUX connections)
BoundaryTransition[render-emit]* (for GPU surface allocations)
FaultEnvelope* (for any fault)
```

## Related

- `schemas/agent-harness-terminal-receipts.schema.json` — terminal receipt schema
- `docs/sourceos/AGENT_HARNESS_TERMINAL_RECEIPTS.md` — receipt capture contract
- sourceos-shell `docs/adr-035-examples.md` — reference fixtures across shell engines
- sourceos-spec `CapabilityContract.json` — capability declaration schema
