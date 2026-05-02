# TurtleTerm Homebrew Packaging

This directory stages Homebrew packaging for TurtleTerm, the SourceOS policy-aware agent terminal workbench built on the WezTerm engine.

The final tap should live in `SourceOS-Linux/homebrew-tap`. Until that tap exists, developers can test the formula directly from this repository.

## Local install

From a local checkout of this repository, install the experimental HEAD formula:

```bash
brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb
```

To reinstall while iterating:

```bash
brew uninstall turtle-term || true
brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb
```

## Test installed commands

```bash
turtle-term paths
turtle-term run -- echo hello
sourceos-term paths
```

`turtle-term` is the product command. `sourceos-term` remains as a compatibility command for existing SourceOS contract work.

## Activate the profile

The formula installs the TurtleTerm WezTerm profile under Homebrew `etc`:

```bash
ln -sf "$(brew --prefix)/etc/turtle-term/wezterm.lua" ~/.wezterm.lua
```

Then launch `wezterm-gui`.

## Future tap flow

After `SourceOS-Linux/homebrew-tap` exists and the formula is copied to `Formula/turtle-term.rb`, the intended install flow is:

```bash
brew tap SourceOS-Linux/tap
brew install --HEAD turtle-term
```

After tagged releases and bottles exist, the intended stable flow is:

```bash
brew install turtle-term
```

## Formula responsibilities

The formula installs `wezterm`, `wezterm-gui`, `wezterm-mux-server`, `turtle-term`, the `sourceos-term` compatibility command, the TurtleTerm profile, and SourceOS terminal documentation.

Windows packaging is postponed until the macOS and Linux Homebrew lane is stable.
