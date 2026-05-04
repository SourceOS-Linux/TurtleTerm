# turtle.nvim

`turtle.nvim` is the first-class Neovim integration for TurtleTerm.

It is a thin client over `turtle-agentd` and `turtle-agentctl`. It does not own agent execution, policy evaluation, or shell authority.

## Commands

```vim
:TurtlePing
:TurtleSessions
:TurtleInspect
:TurtleSummarize
:TurtlePropose echo hello
:TurtleRequestExecution echo hello
:TurtleReceipts
```

## Safety model

- Neovim can collect editor and terminal context.
- Neovim can request summaries and command proposals.
- Neovim cannot directly grant agent shell execution.
- Command execution requests go through TurtleTerm, Policy Fabric, Agent Registry, and SourceOS execution decisions.

## Setup

Add this plugin directory to your Neovim runtime path during development:

```vim
set runtimepath+=/path/to/TurtleTerm/integrations/neovim/turtle.nvim
```

Then run:

```vim
:TurtlePing
```
