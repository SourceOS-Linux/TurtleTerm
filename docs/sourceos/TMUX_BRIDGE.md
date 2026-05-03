# TurtleTerm tmux Bridge

## Purpose

tmux is the first terminal-native integration target for TurtleTerm.

TurtleTerm should work with existing tmux workflows rather than forcing users into a new terminal UI.

## Capabilities

- list tmux sessions, windows, and panes
- attach TurtleTerm session IDs to panes
- capture pane output
- summarize pane output
- propose commands for a pane
- request policy-gated command execution
- emit command receipts
- promote a pane/session into an AgentPlane bundle

## Data mapping

| tmux concept | TurtleTerm concept |
| --- | --- |
| session | workspace/session group |
| window | terminal window/tab group |
| pane | terminal pane |
| pane current path | cwd/workdir |
| pane output | inspect/summarize input |
| command request | ExecutionDecision input |

## Safety

The tmux bridge must not inject commands into panes without a policy decision and explicit execution grant.

## Initial CLI

```bash
turtle-tmux sessions
turtle-tmux panes
turtle-tmux inspect <pane-id>
turtle-tmux summarize <pane-id>
turtle-tmux propose <pane-id> -- "make test"
turtle-tmux request-execution <pane-id> -- "make test"
```
