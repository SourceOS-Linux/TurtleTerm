# TurtleTerm MCP Bridge

## Purpose

The TurtleTerm MCP bridge exposes terminal/session context and safe terminal tools to MCP-compatible clients.

MCP is a tool/context/resource protocol. It is not the authority layer.

## Server tools

- `terminal.sessions`
- `terminal.inspect`
- `terminal.summarize`
- `terminal.propose_command`
- `terminal.request_execution`
- `terminal.receipts`
- `terminal.artifacts`
- `terminal.policy.explain`
- `agent.registry.lookup`
- `agentplane.bundle.create`
- `agentplane.run.request`

## Resources

- terminal session metadata
- command receipts
- AgentPlane artifact refs
- policy decisions
- skill manifests
- release manifests

## Execution rule

`terminal.request_execution` must never directly execute a command. It must return or create an ExecutionDecision and proceed only when Policy Fabric permits execution.

## Client role

TurtleTerm may also act as an MCP client for external tools such as browser automation tools, but browser tasks should route to BearBrowser skills.

## Non-goals

- raw shell server
- unaudited tool execution
- policy bypass
