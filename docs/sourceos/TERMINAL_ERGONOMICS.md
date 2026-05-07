# TurtleTerm Terminal Ergonomics

## Goal

TurtleTerm should reach iTerm-class terminal ergonomics while preserving SourceOS trust boundaries.

The target is not novelty. The target is a terminal-native workbench that feels fast, predictable, searchable, restorable, and governable.

## Core capabilities

### Profiles

Profiles are named execution surfaces:

- local host
- tmux session
- Neovim context
- cloudfog shell
- Agent Machine AgentPod
- policy sandbox
- evidence runner

Each profile carries:

- surface id
- workspace id
- cwd
- policy profile
- receipt requirement
- agent-attachment policy
- environment hints

### Layouts

Layouts describe tabs, panes, commands, working directories, and profile references.

Initial format should be JSON so it can later promote to SourceOS canonical schemas.

### Marks

Marks are operator-visible anchors in a session timeline:

- command started
- command completed
- failure
- policy decision
- receipt emitted
- agent proposal
- handoff to AgentPlane

### Search

Search should cover terminal events, receipts, marks, session summaries, and file/context references. Search is read-only.

### Replay

Replay should not blindly rerun shell history. Replay should produce a reviewable replay plan with receipt references and policy decisions.

### Guarded broadcast

Broadcast input across panes should require explicit confirmation and should never send commands to higher-risk surfaces without policy admission.

## Non-goals

- no ambient agent shell authority
- no hidden execution
- no silent replay
- no unreviewed multi-pane broadcast
- no runtime provider activation without Agent Machine gates

## CLI surface

```bash
turtle-session profiles
turtle-session layout export
turtle-session marks
turtle-session mark "before refactor"
turtle-session search "error"
turtle-session replay-plan
```

## Neovim surface

```vim
:TurtleProfiles
:TurtleMarks
:TurtleMark before refactor
:TurtleSearch error
:TurtleReplayPlan
```
