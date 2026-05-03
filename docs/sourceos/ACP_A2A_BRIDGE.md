# TurtleTerm ACP to A2A Bridge

## Purpose

ACP is the editor/client ingress protocol for TurtleTerm. It should not be treated as a Zed-only compatibility feature.

ACP requests enter TurtleTerm through `turtle-agentd`, are normalized into SourceOS session/action requests, and are routed through A2A when agent delegation is required.

## Flow

```text
ACP client/editor
  → turtle-agentd ACP endpoint
  → SourceOS AgentSession binding
  → ExecutionSurface binding
  → A2A task/session delegation if needed
  → MCP tools/resources if needed
  → Policy Fabric decision for risky actions
  → receipt/artifact response
```

## Supported ACP-originated intents

- inspect current terminal/session
- summarize current terminal/session
- propose command
- request command execution
- delegate task to registered agent
- retrieve receipts
- retrieve artifacts
- explain policy decision
- promote session into AgentPlane bundle

## Policy boundary

ACP can request. It cannot authorize.

Authorization comes from Policy Fabric and is recorded as an ExecutionDecision.

## A2A boundary

ACP can trigger A2A delegation only when:

1. target agent is registered,
2. target skill is registered,
3. execution surface is valid,
4. policy decision permits the delegation,
5. receipt emission is configured.

## Editor targets

- Zed / ACP-compatible clients for protocol validation.
- VS Code through native extension first, ACP compatibility where useful.
- JetBrains and Neovim through native plugins or ACP-compatible adapters later.

## Non-goals

- embedding Zed
- depending on Zed internals
- making ACP the TurtleTerm authority layer
- allowing ACP clients to bypass policy
