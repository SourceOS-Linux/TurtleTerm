# TurtleTerm Neovim Integration

## Decision

Neovim is a first-class TurtleTerm integration target.

TurtleTerm plus Neovim should be sufficient for users who do not want VS Code, JetBrains, or other heavyweight editor surfaces.

## Product goal

Make terminal-native development feel complete:

```text
TurtleTerm + tmux + Neovim + turtle-agentd
```

The user should be able to edit, inspect terminal state, request command proposals, review receipts, and delegate governed agent work without leaving the terminal-native stack.

## Integration shape

The Neovim plugin should be a thin client over `turtle-agentd`.

It should not own agent execution, policy evaluation, or shell authority.

## Proposed package

```text
integrations/neovim/turtle.nvim/
```

## Initial commands

```vim
:TurtleSummarize
:TurtleInspect
:TurtlePropose
:TurtleRequestExecution
:TurtleReceipts
:TurtlePolicyExplain
:TurtlePromoteAgentPlane
```

## Context sources

- current buffer path
- selected range
- diagnostics
- git branch
- working directory
- active terminal buffer
- tmux pane, when available
- TurtleTerm session ID

## Safety rules

1. Neovim can collect context.
2. Neovim can request summaries and proposals.
3. Neovim cannot directly execute agent commands.
4. Execution requests go through `turtle-agentd` and Policy Fabric.
5. Agent delegation goes through Agent Registry and A2A.
6. Reproducible or high-risk execution is promoted to AgentPlane.

## UX target

A Neovim user should be able to stay in the terminal-native environment:

```text
:TurtleSummarize        summarize current terminal/session
:TurtlePropose          propose command for current repo/buffer
:TurtleRequestExecution request policy-gated command execution
:TurtleReceipts         inspect receipts
:TurtlePolicyExplain    explain why execution was allowed/denied/rewritten
```

## Non-goals

- replacing Neovim
- embedding a separate editor
- bypassing Policy Fabric
- raw shell execution from plugin code
- forcing VS Code or JetBrains workflows
