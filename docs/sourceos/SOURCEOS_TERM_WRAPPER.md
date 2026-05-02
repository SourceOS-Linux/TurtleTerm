# SourceOS Term Wrapper v0

## Purpose

`assets/sourceos/bin/sourceos-term` is the first executable SourceOS terminal sidecar surface for this fork.

It runs a command, mirrors stdout/stderr back to the active terminal, and emits:

1. a `sourceos.terminal.session.v0` event,
2. a `command.started` event,
3. a `command.completed` event,
4. a durable `sourceos.terminal.receipt.v0` JSON receipt.

This gives AgentPlane, Matrix/AgentTerm, PolicyFabric, and workstation-contract tooling structured terminal evidence without granting agents raw shell authority.

## Usage

From the repository root:

```bash
python3 assets/sourceos/bin/sourceos-term run -- echo hello
```

Equivalent shorthand:

```bash
python3 assets/sourceos/bin/sourceos-term -- echo hello
python3 assets/sourceos/bin/sourceos-term echo hello
```

Print event and receipt paths:

```bash
python3 assets/sourceos/bin/sourceos-term paths
```

## Environment variables

| Variable | Purpose | Default |
| --- | --- | --- |
| `SOURCEOS_TERMINAL_SESSION_ID` | Stable terminal session ID. | Generated per invocation if unset. |
| `SOURCEOS_TERMINAL_EVENTS` | NDJSON event stream path. | `$XDG_RUNTIME_DIR/sourceos/terminal/events.ndjson` |
| `SOURCEOS_TERMINAL_RECEIPTS` | Receipt root directory. | `$XDG_STATE_HOME/sourceos/terminal/receipts` |
| `SOURCEOS_WORKSPACE` | SourceOS workspace ID/name. | `sourceos` |
| `SOURCEOS_ACTOR_ID` | Actor executing the command. | `human:$USER` |
| `SOURCEOS_POLICY_BUNDLE_ID` | Policy bundle reference. | `unbound` |
| `SOURCEOS_REQUESTED_BY` | Requesting actor. | `SOURCEOS_ACTOR_ID` |
| `SOURCEOS_APPROVED_BY` | Approval/policy actor. | `SOURCEOS_POLICY_BUNDLE_ID` |
| `SOURCEOS_EXECUTION_DOMAIN` | Explicit execution domain. | Auto-detected. |

## Output paths

Default event stream:

```text
$XDG_RUNTIME_DIR/sourceos/terminal/events.ndjson
```

Default receipt directory:

```text
$XDG_STATE_HOME/sourceos/terminal/receipts/<session_id>/
```

## Event shape

The emitted JSON shapes follow `docs/sourceos/SESSION_CONTRACT.md`.

The wrapper currently records stdout/stderr digests but does not persist full stdout/stderr logs. That is intentional for v0. Replay and log-retention policy should be decided by PolicyFabric and workstation-contract integration rather than hardcoded into the wrapper.

## Agent safety posture

This wrapper does not give agents a shell.

It gives the terminal ecosystem structured evidence. Future agent bridges should call this wrapper only through explicit SourceOS policy grants.

## Known limitations

- Uses Python standard library only.
- Does not yet enforce policy; it only records policy references.
- Does not persist full stdout/stderr logs.
- Does not yet emit a formal JSON Schema file.
- Does not yet integrate with WezTerm internals.
- Command strings are recorded in shell-display form, not as a fully lossless argv array.

## Next steps

1. Add JSON Schema files for session, event, and receipt objects.
2. Add smoke tests that run the wrapper and validate emitted JSON.
3. Add shell integration helpers for Bash, Zsh, and Fish.
4. Add a minimal local sidecar that tails the event stream.
5. Wire policy checks before `terminal.execute_command` mode is exposed to agents.
