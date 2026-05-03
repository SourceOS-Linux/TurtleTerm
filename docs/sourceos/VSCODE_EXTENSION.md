# TurtleTerm VS Code Extension

## Purpose

The VS Code-compatible extension is the first mainstream editor integration target for TurtleTerm.

It should support VS Code, VSCodium, and Cursor-like forks where extension compatibility permits.

## Principle

The extension is a client. It does not own agent execution.

All execution and delegation flows go through `turtle-agentd`.

## Commands

- `TurtleTerm: Summarize Terminal`
- `TurtleTerm: Propose Command`
- `TurtleTerm: Request Execution`
- `TurtleTerm: Show Receipts`
- `TurtleTerm: Explain Policy Decision`
- `TurtleTerm: Promote Session to AgentPlane Bundle`
- `TurtleTerm: Delegate via A2A`

## Context sources

- active editor file
- workspace folder
- integrated terminal cwd
- selected terminal text
- active git branch
- diagnostics/problems
- selected code region

## Safety

The extension may collect context and request actions. It may not bypass Policy Fabric or execute commands directly on behalf of an agent.

## Initial package

```text
integrations/vscode/turtle-term-vscode/
```

The package should be MIT licensed where authored by us.
