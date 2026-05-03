# TurtleTerm A2A-MCP-ZeroTrust Bridge

## Purpose

This bridge defines how TurtleTerm participates in the SourceOS/SocioProphet a2a-mcp-zerotrust fabric.

TurtleTerm does not expose raw shell authority through MCP, A2A, ACP, editor plugins, or terminal adapters. Every action that can mutate state, execute commands, delegate work, access protected paths, contact the network, or create artifacts must pass through a zero-trust decision flow.

## Protocol positioning

- ACP is editor/client ingress.
- A2A is registered-agent delegation.
- MCP is tool/context/resource access.
- Policy Fabric is policy governance.
- Agent Registry is identity and capability registration.
- AgentPlane is evidence-producing execution.

## Request flow

```text
client request
  → turtle-agentd
  → normalize request
  → resolve agent/skill/provider identity
  → build ExecutionSurface
  → ask Policy Fabric
  → emit ExecutionDecision
  → execute locally only if permitted and in scope
  → delegate through A2A or AgentPlane if required
  → emit receipt / artifacts / replay references
```

## Zero-trust rules

1. MCP tools cannot directly execute shell commands.
2. A2A delegates only to registered agents.
3. ACP requests cannot bypass policy.
4. Host execution is high sensitivity.
5. Elevated execution is denied by default.
6. Protected path access is denied unless explicitly granted.
7. Network egress requires policy-bound mode.
8. Agent handoff requires SkillManifest and policy binding.
9. Every execution request produces an ExecutionDecision.
10. Every completed task produces a receipt.

## Request classes

| Request | Transport | Authority |
| --- | --- | --- |
| inspect terminal/session | MCP or ACP | audit-only, policy optional |
| summarize terminal/session | MCP or ACP | audit-only, policy optional |
| propose command | MCP or ACP | no execution, policy optional |
| execute command | MCP, ACP, or A2A | Policy Fabric required |
| delegate to agent | A2A | Agent Registry + Policy Fabric required |
| browser handoff | A2A + MCP | BearBrowser skill + Policy Fabric required |
| AgentPlane run | A2A or direct bridge | AgentPlane bundle validation required |

## Artifacts

The bridge should emit:

- ExecutionDecision reference
- terminal command receipt
- SessionReceipt
- AgentPlane artifact references when applicable
- replay pointer
- policyRef
- skillRef
- agentRef

## Non-goals

- raw shell over MCP
- unregistered A2A agents
- bypassing Policy Fabric
- replacing AgentPlane
- replacing BearBrowser
