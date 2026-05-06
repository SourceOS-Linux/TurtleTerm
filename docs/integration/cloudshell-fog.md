# CloudShell FOG Integration Profile v0 — TurtleTerm

## Purpose

TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench for trusted command execution, terminal receipts, agent delegation, and reproducible operator workflows.

CloudShell FOG is the browser/fog/cloud shell execution plane for session lifecycle, placement, PTY attach, runtime allocation, and audit.

This profile defines how TurtleTerm should integrate with CloudShell FOG while preserving TurtleTerm as the owner of terminal command receipt semantics.

## Ownership boundary

### TurtleTerm owns

- local/operator command lifecycle receipts
- SourceOS terminal session/event/receipt schemas
- stdout/stderr digest capture for command execution
- operator terminal event stream and receipt paths
- local agent gateway and terminal CLI behavior

### CloudShell FOG owns

- browser/fog/cloud shell session lifecycle
- WSS PTY attach contract
- fog/cloud placement metadata
- Kubernetes/fog runtime connector behavior
- CloudShell audit events
- runtime allocation and teardown semantics

## Integration principle

TurtleTerm should expose or preserve receipt metadata that allows CloudShell FOG sessions and audit events to correlate with local/operator command receipts.

TurtleTerm should not absorb CloudShell FOG's placement engine or runtime connector responsibilities.

## Environment propagation

When a TurtleTerm workflow is launched in the context of a CloudShell FOG session, the launcher MAY set:

- `SOURCEOS_TERMINAL_SESSION_ID` = CloudShell session ID or derived stable terminal session ID
- `SOURCEOS_WORKSPACE` = CloudShell workspace or project identifier, if known
- `SOURCEOS_ACTOR_ID` = CloudShell authenticated subject or mapped SourceOS actor identity
- `SOURCEOS_POLICY_BUNDLE_ID` = CloudShell policy/profile identifier
- `SOURCEOS_EXECUTION_DOMAIN` = `cloudshell-fog`, `k8s`, `fog`, or a more specific domain

TurtleTerm should preserve these values in session/event/receipt outputs rather than rewriting them with local-only defaults.

## Receipt correlation fields

Where available, CloudShell FOG metadata SHOULD be attached to TurtleTerm receipt context:

- CloudShell session ID
- CloudShell placement region
- CloudShell placement node ID
- CloudShell trust tier
- CloudShell placement reasons
- runtime image or runtime profile
- runtime namespace/pod identity when applicable

## Event mapping

| TurtleTerm / SourceOS terminal concept | CloudShell FOG concept |
|---|---|
| `sourceos.terminal.session.v0` | `session.created` / shell session context |
| `command.started` | command execution within attached shell context |
| `command.completed` | completed command plus receipt pointer |
| command stdout/stderr digests | command-level evidence, not PTY stream replacement |
| `execution_domain` | CloudShell runtime / placement execution domain |
| policy bundle ID | CloudShell policy/profile context |

## Non-goals

- TurtleTerm does not replace CloudShell FOG's browser shell or WSS PTY contract.
- TurtleTerm does not own CloudShell FOG's Kubernetes/fog placement engine.
- CloudShell FOG does not need to capture every PTY byte as a TurtleTerm command receipt by default.

## Open questions

1. Should SourceOS terminal schemas remain in TurtleTerm or move to a shared terminal-contracts repository?
2. Should TurtleTerm support a `cloudshell-fog` receipt enrichment mode with explicit placement fields?
3. Should AgentPlane become the canonical bridge for launching TurtleTerm-backed workflows from CloudShell FOG?

## Tracking

- TurtleTerm: issue #1
- CloudShell FOG: SocioProphet/cloudshell-fog#35
