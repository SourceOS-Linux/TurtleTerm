# TurtleTerm Language Intelligence

## Goal

TurtleTerm should support Agha-style language intelligence for terminal-native workflows: Tree-sitter syntax structure, LSP diagnostics and code actions, semantic indexing, and Neovim-first command surfaces.

This is not an editor replacement. TurtleTerm exposes language intelligence to terminal sessions, tmux panes, Neovim buffers, cloudfog surfaces, and governed agent proposals.

## Product posture

TurtleTerm plus tmux plus Neovim should be enough for users who do not want VS Code, JetBrains, or a heavyweight GUI editor.

Language intelligence must remain safe by default:

- diagnostics are read-only;
- symbols are read-only;
- explanations are read-only;
- patch proposals are proposals, not writes;
- command execution remains policy-gated;
- agent delegation remains Agent Registry and Policy Fabric gated.

## Components

### turtle-language

`turtle-language` is the terminal CLI surface for read-only language context.

Initial commands:

```bash
turtle-language diagnostics <file>
turtle-language symbols <file>
turtle-language explain-selection <file> --start 1 --end 20
turtle-language propose-patch <file> --prompt "make this safer"
turtle-language index <root>
```

### turtle.nvim

Neovim exposes the same capabilities:

```vim
:TurtleDiagnostics
:TurtleSymbols
:TurtleExplainSelection
:TurtleProposePatch make this safer
```

### Future Tree-sitter layer

Tree-sitter should provide:

- syntax-aware selection metadata;
- symbol extraction;
- folding anchors;
- semantic regions for prompt boundaries;
- syntax-aware diff review;
- language-specific receipt context.

### Future LSP layer

LSP should provide:

- diagnostics;
- hover;
- definitions;
- references;
- document symbols;
- workspace symbols;
- code actions;
- rename/refactor proposals.

### Future semantic index layer

Semantic indexing should provide:

- repository structure summaries;
- symbol graph;
- file-to-session references;
- function/class search;
- agent proposal grounding;
- AgentPlane evidence references.

## Non-goals

- direct file mutation without review;
- replacing Neovim;
- bypassing LSP clients;
- bypassing Policy Fabric;
- turning diagnostics into automatic shell execution;
- giving agents ambient write access.
