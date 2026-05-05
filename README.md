# TurtleTerm

> They say the world was built on the back of a turtle. TurtleTerm carries the shell on its back.

TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench for trusted command execution, terminal receipts, agent delegation, and reproducible operator workflows.

TurtleTerm presents its own product surface: TurtleTerm launchers, TurtleTerm profile, TurtleTerm agent gateway, TurtleTerm release artifacts, and TurtleTerm skill manifests. Third-party notices and required license attribution are preserved in the repository license files and release artifacts.

## Install

Tapless Homebrew install from this repository:

```bash
brew install --HEAD https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/packaging/homebrew/Formula/turtle-term.rb
```

Preferred public Homebrew flow after the tap is published:

```bash
brew install SourceOS-Linux/tap/turtle-term
```

Current tap HEAD formula flow after the tap is published:

```bash
brew install --HEAD SourceOS-Linux/tap/turtle-term
```

Local checkout flow:

```bash
brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb
```

Direct release artifact installer after the first TurtleTerm release exists:

```bash
curl -fsSL https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/packaging/scripts/install-turtle-term.sh | bash
```

See `docs/sourceos/INSTALL.md` for full install, profile activation, and validation instructions.

## Launch

```bash
turtleterm
```

## Commands

```bash
turtle-term paths
turtle-term run -- echo hello
turtle-term office plan --title "Demo Report" --artifact-type document --format md
turtle-term /office plan --office-action convert --input ./demo.docx --to pdf
turtle-term office evidence inspect ./office-evidence.json
turtle-agentctl --stdio ping
turtle-tmux panes
```

`turtle-term` is the command wrapper. `turtleterm` is the graphical launcher. `sourceos-term` remains available for SourceOS contract compatibility.

The `office` / `/office` operator surface does not implement an office suite inside TurtleTerm. It produces SourceOS Office operator plans that point to `sourceosctl office`, records the receipt command to run through TurtleTerm, and summarizes `OfficeArtifactEvidence` runtime contract IDs when present.

## Product surfaces

- TurtleTerm graphical launcher
- TurtleTerm mux launcher
- TurtleTerm command wrapper
- TurtleTerm local agent gateway
- TurtleTerm agent CLI
- TurtleTerm tmux bridge
- TurtleTerm Office operator flow planning
- TurtleTerm skill manifests
- TurtleTerm turtle icon
- TurtleTerm release artifacts, manifests, SBOMs, and attestations

## License and notices

TurtleTerm is MIT licensed. Required third-party notices are preserved in `LICENSE.md` and release artifacts.
