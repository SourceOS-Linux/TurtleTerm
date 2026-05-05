# TurtleTerm Product Parity Roadmap

## Goal

TurtleTerm should become a Linux-first terminal-native development surface that combines:

- iTerm-class terminal ergonomics
- Zed-class agent/editor workflow
- Agha-style language intelligence through Tree-sitter, LSP, and semantic indexing
- AgentCore-style runtime, identity, gateway, memory, and observability primitives
- SourceOS policy, receipts, and AgentPlane evidence

This is not an editor clone. TurtleTerm is the trusted terminal/session fabric for terminal-native users, especially users who prefer TurtleTerm + tmux + Neovim over VS Code or JetBrains.

## Product axes

### Terminal ergonomics

TurtleTerm should provide excellent panes, tabs, profiles, launchers, search, scrollback, replay, shell integration, tmux attachment, cloud/fog surface selection, and session restoration.

### Language intelligence

TurtleTerm should expose code intelligence to terminal-native workflows through Tree-sitter parsing, LSP diagnostics/completion/navigation, DAP hooks, stack-graph/semantic indexing where useful, and Neovim-first integration.

### Agent workflow

TurtleTerm should expose inspect, summarize, propose, request-execution, delegate, receipts, policy explanation, and AgentPlane promotion flows from terminal panes, tmux panes, Neovim buffers, and cloudfog surfaces.

### Runtime trust

TurtleTerm should not grant ambient shell authority. Every risky command, agent attachment, networked surface, protected path, browser handoff, or cloudfog action becomes a policy-mediated execution decision.

### Observability and memory

TurtleTerm should record session telemetry, command receipts, agent receipts, policy decisions, replay references, and agent memory references without turning the terminal into an opaque chat box.

## First-class surfaces

1. TurtleTerm GUI/profile
2. tmux bridge
3. Neovim integration
4. cloudfog-shell surfaces
5. MCP tools/resources
6. A2A delegation
7. ACP ingress
8. VS Code extension
9. Zed ACP validation
10. JetBrains plugin later

## Definition of parity

TurtleTerm reaches parity when a terminal-native user can stay inside TurtleTerm + tmux + Neovim and get:

- iTerm-grade pane/profile/search/session ergonomics
- Zed-grade agent workflow and contextual editing support
- Agha-grade Tree-sitter/LSP language intelligence
- AgentCore-grade runtime/session/memory/gateway/observability model
- SourceOS-grade policy, receipts, replay, and evidence
