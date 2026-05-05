# TurtleTerm and Superconscious Integration

## Decision

TurtleTerm integrates with Superconscious as an operator/session surface, not as a competing cognition loop.

Superconscious owns the governed cognition/control loop: task trees, safe operational traces, skill activation, tool use, memory decisions, model routing, policy admission, approvals, benchmarks, replay plans, and AgentPlane-compatible evidence.

TurtleTerm owns terminal/session UX: panes, tabs, tmux attachment, Neovim context, command proposals, receipt capture, policy prompts, cloudfog surface selection, and operator-facing agent handoff.

## Boundary

TurtleTerm sends Superconscious:

- terminal observations
- tmux pane observations
- Neovim context observations
- cloudfog surface observations
- command proposals
- command outcomes
- receipt references
- policy decision references
- AgentPlane artifact references

Superconscious sends TurtleTerm:

- plan summaries
- next-action proposals
- safe operational traces
- approval requests
- memory handling decisions
- model-route rationale
- skill activation requests
- replay-plan references

Superconscious must not gain ambient shell authority through TurtleTerm.

## Flow

```text
TurtleTerm terminal/session event
  -> turtle-agentd observation
  -> Superconscious reasoning run
  -> policy admission request when needed
  -> next-action proposal or approval request
  -> TurtleTerm displays proposal
  -> execution request becomes ExecutionDecision
  -> receipt and replay references flow back to Superconscious
```

## Trust surface

TurtleTerm is a declared trust surface because it starts processes, observes terminal state, exposes local sockets, mediates agent requests, and can request shell execution.

TurtleTerm should eventually carry a `TRUST_SURFACE.yaml` aligned with the Superconscious trust-surface protocol.

## Non-goals

- TurtleTerm does not own recursive cognition.
- Superconscious does not own terminal execution.
- Superconscious does not bypass Policy Fabric.
- Superconscious does not bypass Agent Registry.
- Superconscious does not bypass AgentPlane evidence.
