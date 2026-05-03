# TurtleTerm Policy Fabric Bridge

## Purpose

TurtleTerm execution authority flows through Policy Fabric.

TurtleTerm may collect context, inspect sessions, summarize state, and propose actions. It may not execute risky actions without a Policy Fabric-backed ExecutionDecision.

## Requests requiring policy

- `terminal.execute_command`
- `terminal.attach`
- `terminal.create_artifact`
- `terminal.open_pr`
- `agent.delegate`
- `browser.handoff`
- `network.egress`
- `host.execution`
- `elevated.execution`
- `protected_path.read`
- `protected_path.write`

## Decision outcomes

- allow
- deny
- ask
- defer
- rewrite

## Bridge flow

```text
request
  → normalize TurtleTerm action
  → resolve agent/skill/surface
  → submit policy evaluation
  → receive decision
  → emit ExecutionDecision
  → satisfy obligations
  → execute or block
  → emit receipt
```

## Receipt requirements

Receipts should record:

- policyRef
- decisionRef
- decision outcome
- obligations
- execution surface
- agentRef
- skillRef
- command/tool request
- artifacts

## Non-goals

- local allowlist bypass
- direct host execution without policy
- invisible rewrite of commands
