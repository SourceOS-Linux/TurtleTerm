# TurtleTerm Install Guide

## Fast path: tapless Homebrew install

Before the public tap exists, users can install directly from the raw formula in this repository:

```bash
brew install --HEAD https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/packaging/homebrew/Formula/turtle-term.rb
```

This is the current easiest no-checkout install path for macOS and Linux.

Then launch TurtleTerm:

```bash
turtleterm
```

The installed profile is `turtleterm.lua`.

## Public tap path

After the public tap exists:

```bash
brew install SourceOS-Linux/tap/turtle-term
```

For the current HEAD formula through the tap:

```bash
brew install --HEAD SourceOS-Linux/tap/turtle-term
```

From a local checkout:

```bash
brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb
```

## Direct release artifact install

For users who do not want Homebrew, use the release artifact installer after the first TurtleTerm release exists:

```bash
curl -fsSL https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/packaging/scripts/install-turtle-term.sh | bash
```

Override install prefix:

```bash
TURTLE_TERM_PREFIX=/usr/local bash packaging/scripts/install-turtle-term.sh
```

Install a specific release:

```bash
TURTLE_TERM_VERSION=turtle-term-v0.1.0 bash packaging/scripts/install-turtle-term.sh
```

Skip Homebrew fallback entirely:

```bash
TURTLE_TERM_USE_BREW=never bash packaging/scripts/install-turtle-term.sh
```

## Validate install

```bash
turtleterm --version || true
turtle-term paths
turtle-term run -- echo turtle-term-ok
turtle-term office plan --title "Demo Report" --artifact-type document --format md
turtle-agentctl --stdio ping
turtle-agent-status --json
```

## Activate TurtleTerm profile

Homebrew profile path:

```bash
ln -sf "$(brew --prefix)/etc/turtle-term/turtleterm.lua" ~/.wezterm.lua
```

Direct install profile path:

```bash
ln -sf "$HOME/.local/etc/turtle-term/turtleterm.lua" ~/.wezterm.lua
```

The file name `turtleterm.lua` is the product-facing TurtleTerm profile. It may internally derive from upstream terminal profile conventions, but operator docs should use the TurtleTerm product surface name.

## Windows

Windows packaging is postponed until the Linux/macOS release path is stable.
