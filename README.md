# TurtleTerm

> They say the world was built on the back of a turtle. TurtleTerm is built on the back of WezTerm.

TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench built on the WezTerm engine.

WezTerm remains the credited upstream terminal emulator and multiplexer. TurtleTerm layers SourceOS session contracts, command receipts, policy-aware execution lanes, Matrix/AgentTerm integration, and macOS/Linux packaging on top of that engine.

## Install

Current local Homebrew formula install:

```bash
brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb
```

Future public tap flow:

```bash
brew tap SourceOS-Linux/tap
brew install --HEAD turtle-term
```

## Commands

```bash
turtle-term paths
turtle-term run -- echo hello
sourceos-term paths
```

`turtle-term` is the product command. `sourceos-term` remains as a compatibility command for SourceOS contract work.

## SourceOS additions

SourceOS-specific docs, profiles, packaging, and sidecar-friendly wrappers live under:

- `docs/sourceos/`
- `assets/sourceos/`
- `packaging/homebrew/`

## License and attribution

This fork preserves upstream WezTerm attribution and licensing. See `LICENSE.md` for the MIT license and bundled font license notes.
