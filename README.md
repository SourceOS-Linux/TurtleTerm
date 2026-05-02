# TurtleTerm

> They say the world was built on the back of a turtle. TurtleTerm is built on the back of WezTerm.

TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench built on the WezTerm engine.

WezTerm remains the credited upstream terminal emulator and multiplexer. TurtleTerm layers SourceOS session contracts, command receipts, policy-aware execution lanes, Matrix/AgentTerm integration, and macOS/Linux packaging on top of that engine.

## Install

Preferred public Homebrew flow after the tap is published:

```bash
brew install SourceOS-Linux/tap/turtle-term
```

Current HEAD formula flow:

```bash
brew install --HEAD SourceOS-Linux/tap/turtle-term
```

Local checkout flow before the tap is published:

```bash
brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb
```

Direct release artifact installer after the first TurtleTerm release exists:

```bash
curl -fsSL https://raw.githubusercontent.com/SourceOS-Linux/wezterm/main/packaging/scripts/install-turtle-term.sh | bash
```

See `docs/sourceos/INSTALL.md` for full install, profile activation, and validation instructions.

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
- `packaging/scripts/`

## License and attribution

This fork preserves upstream WezTerm attribution and licensing. See `LICENSE.md` for the MIT license and bundled font license notes.
