# TurtleTerm Homebrew Packaging

This directory stages Homebrew packaging for TurtleTerm, the SourceOS policy-aware agent terminal fabric.

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
turtleterm --version || true
turtle-term paths
turtle-term run -- echo hello
turtle-agentctl --stdio ping
sourceos-term paths
```

`turtleterm` is the graphical product launcher. `turtle-term` is the command wrapper. `sourceos-term` remains available for SourceOS contract compatibility.

## Activate the profile

The formula installs the TurtleTerm profile under Homebrew `etc`:

```bash
ln -sf "$(brew --prefix)/etc/turtle-term/wezterm.lua" ~/.wezterm.lua
```

Then launch TurtleTerm:

```bash
turtleterm
```

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

The formula installs TurtleTerm launchers, TurtleTerm command tools, the TurtleTerm profile, TurtleTerm skill manifests, TurtleTerm brand assets, and SourceOS terminal documentation. Private terminal runtime binaries are installed under `libexec/turtle-term` and are not exposed as product commands.

Windows packaging is postponed until the macOS and Linux Homebrew lane is stable.
