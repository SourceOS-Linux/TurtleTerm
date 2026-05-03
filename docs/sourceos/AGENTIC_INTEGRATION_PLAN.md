# TurtleTerm Agentic Integration Plan

## Product decision

TurtleTerm is the trusted terminal/session execution layer for SourceOS.

It does not replace editors, terminals, AgentPlane, Policy Fabric, Agent Registry, MCP, A2A, ACP, or BearBrowser. It connects them through a governed terminal/session fabric.

## Correct integration model

```text
VS Code / VSCodium / Cursor-like forks
Zed / ACP-compatible clients
JetBrains IDEs
Neovim
tmux
TurtleTerm / WezTerm
BearBrowser
        ↓
TurtleTerm local agent gateway
        ↓
ACP ingress + A2A delegation + MCP tools/resources
        ↓
Agent Registry + Policy Fabric + SourceOS contracts
        ↓
AgentPlane execution, evidence, and replay
```

## Protocol roles

- ACP: editor/client-to-agent interface.
- A2A: agent-to-agent delegation and task/session flow.
- MCP: tool, context, prompt, and resource access.
- Policy Fabric: policy authoring, validation, review, governance, and release expectations.
- Agent Registry: registered agent, skill, provider, and execution-surface identity.
- AgentPlane: evidence-producing execution, placement, run, replay, promotion, and reversal.
- SourceOS contracts: canonical schemas for sessions, decisions, surfaces, skills, receipts, telemetry, and release artifacts.

## Invariant

TurtleTerm must not grant agents ambient shell authority.

Every risky action becomes an ExecutionDecision: allow, deny, ask, defer, or rewrite.

## First-class integration targets

1. tmux bridge for terminal-native users.
2. VS Code-compatible extension for mainstream editor users.
3. ACP ingress that feeds A2A.
4. MCP bridge for tools/resources.
5. A2A gateway for registered-agent delegation.
6. Agent Registry bridge.
7. Policy Fabric bridge.
8. AgentPlane bridge.
9. Zed ACP validation.
10. JetBrains plugin.
11. Neovim plugin.
12. BearBrowser Stagehand/Playwright handoff.

## Development tracks

### Track A: trust fabric

- turtle-agentd
- Agent Registry bridge
- Policy Fabric bridge
- ExecutionDecision mapping
- ExecutionSurface mapping
- SessionReceipt mapping
- AgentPlane bridge

### Track B: user surfaces

- tmux bridge
- VS Code extension
- ACP ingress
- MCP bridge
- A2A gateway
- JetBrains plugin
- Neovim plugin
- BearBrowser handoff

## World-class v0 standard

A user should be able to install TurtleTerm, attach it to an existing terminal/editor workflow, ask for session inspection or command proposals, and know exactly who acted, what policy applied, what ran, where it ran, what changed, and what receipt proves it.
