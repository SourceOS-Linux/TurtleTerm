# TurtleTerm: Superconscious ReasoningRun Task Tree and Evidence Rendering

## Purpose (issue TurtleTerm #6)

Superconscious emits governed recursive reasoning artifacts. SourceOS reasoning contracts
are being promoted into `SourceOS-Linux/sourceos-spec`. TurtleTerm should render these
as an operator-facing trace/evidence console within the terminal session pane.

## Design

### Rendering surface

TurtleTerm renders ReasoningRun traces in a dedicated split pane alongside the active terminal.
The pane is:

- Opened by `Ctrl+Shift+R` or via the command palette: `Open ReasoningRun trace`
- Populated from the local `~/.local/share/turtleterm/reasoning/<session-id>/` directory
- Updated live when the active session is backed by an agentplane-governed agent

### Data format

Each ReasoningRun is a JSONL file:

```
<run_ref>.jsonl
```

Each line is one of:
- `{"kind": "run-start", "run_ref": "...", "agent_ref": "...", "goal_ref": "...", "started_at": "..."}`
- `{"kind": "step", "step_index": N, "step_kind": "premise|inference|conclusion|fork", "confidence": 0.0–1.0, "suppress_mutation": true|false}`
- `{"kind": "run-end", "outcome": "success|failure|suppressed", "confidence": 0.0–1.0, "receipt_ref": "..."}`
- `{"kind": "fault", "fault_class": "...", "severity": "fatal|non-fatal", "suppress_mutation": true}`

### Example JSONL trace

```jsonl
{"kind": "run-start", "run_ref": "urn:srcos:reasoning-run:sc:20260718T100000Z", "agent_ref": "urn:srcos:agent:superconscious:2026", "goal_ref": "urn:srcos:goal:patch-review:20260718", "started_at": "2026-07-18T10:00:00Z"}
{"kind": "step", "step_index": 0, "step_kind": "premise", "confidence": 0.97, "suppress_mutation": false}
{"kind": "step", "step_index": 1, "step_kind": "inference", "confidence": 0.91, "suppress_mutation": false}
{"kind": "step", "step_index": 2, "step_kind": "conclusion", "confidence": 0.88, "suppress_mutation": false, "policy_decision_ref": "urn:srcos:policy-decision:sc-mutation-admit-20260718"}
{"kind": "run-end", "outcome": "success", "confidence": 0.88, "receipt_ref": "urn:srcos:receipt:sc:20260718T100015Z"}
```

### Pane layout

```
┌─────────────────────────────────────────────────────────┐
│ ReasoningRun Trace — urn:srcos:reasoning-run:sc:2026... │
├───────────────────────────────────────────────┬─────────┤
│ Step  Kind        Confidence  Suppress         │ Status  │
│  0    premise     0.97        ✗                │         │
│  1    inference   0.91        ✗                │ success │
│  2    conclusion  0.88        ✗                │         │
├───────────────────────────────────────────────┴─────────┤
│ Outcome: success  Confidence: 0.88  Receipt: ↗           │
└─────────────────────────────────────────────────────────┘
```

- `suppress_mutation=true` steps are highlighted in amber
- `fault` lines are highlighted in red
- Confidence < 0.70 triggers a visual warning indicator
- `run-end` with `receipt_ref` shows a clickable `↗` link to the evidence record

## Integration boundary

- TurtleTerm reads ReasoningRun JSONL files; it does NOT generate them
- Superconscious is the sole authority for writing ReasoningRun artifacts
- AgentPlane delivers the artifacts to the local path during governed sessions
- TurtleTerm never exposes raw step content — only kind, confidence, and suppress flag

## Implementation status

The rendering pane is currently a stub. The data model and JSONL format are defined here.
The live implementation requires:

1. AgentPlane delivering JSONL to `~/.local/share/turtleterm/reasoning/`
2. A Lua event hook watching that directory for new files
3. A Rust pane renderer reading the JSONL and emitting the table above

Tracking: issue TurtleTerm #6.

## Related

- `docs/sourceos/SUPERCONSCIOUS_INTEGRATION.md` — session boundary and evidence contract
- `docs/sourceos/AGENT_HARNESS_TERMINAL_RECEIPTS.md` — receipt capture
- `sourceos-spec/SourceOS-Linux` — ReasoningAssay, ValidatorReceipt, LocalReasoningFailure schemas
- `agent-term` `reasoning_run.py` — same data model for terminal ChatOps
