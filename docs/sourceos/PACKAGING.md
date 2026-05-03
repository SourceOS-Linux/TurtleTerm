# TurtleTerm Packaging Plan

## Purpose

Make TurtleTerm installable with Homebrew on macOS and Linux first.

TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench product. Public package, command, profile, icon, and documentation surfaces should say TurtleTerm. Required third-party notices are preserved in license and notice files.

Windows packaging is intentionally postponed until the macOS and Linux Homebrew path is stable.

## Product package name

Canonical Homebrew formula name:

```text
turtle-term
```

The internal contract namespace remains `sourceos.*` because receipts, policy grants, and event schemas are SourceOS platform contracts. The user-facing product, package, and CLI name is TurtleTerm.

## Target install modes

### v0: Homebrew HEAD formula

Until TurtleTerm tags releases and publishes bottles, install from Git head:

```bash
brew install --HEAD turtle-term
```

For local development from this repository:

```bash
brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb
```

### v1: Homebrew tap

Create a dedicated tap repository:

```text
SourceOS-Linux/homebrew-tap
```

Expected tap layout:

```text
Formula/turtle-term.rb
README.md
.github/workflows/
```

Expected user flow:

```bash
brew tap SourceOS-Linux/tap
brew install --HEAD turtle-term
```

After tagged releases exist:

```bash
brew install turtle-term
```

## What the formula should install

The Homebrew package should install TurtleTerm launchers, TurtleTerm command tools, the TurtleTerm profile, TurtleTerm skill manifests, TurtleTerm brand assets, SourceOS terminal docs, and private terminal runtime files under `libexec/turtle-term`.

Expected installed paths:

```text
$(brew --prefix)/bin/turtleterm
$(brew --prefix)/bin/turtleterm-mux-server
$(brew --prefix)/bin/turtle-term
$(brew --prefix)/bin/turtle-agentd
$(brew --prefix)/bin/turtle-agentctl
$(brew --prefix)/bin/turtle-tmux
$(brew --prefix)/bin/sourceos-term
$(brew --prefix)/etc/turtle-term/turtleterm.lua
$(brew --prefix)/share/turtle-term/brand/
$(brew --prefix)/share/turtle-term/skills/
$(brew --prefix)/share/turtle-term/sourceos/
$(brew --prefix)/libexec/turtle-term/
```

## Build posture

The current formula is experimental and source-build oriented. It should remain `--HEAD` until we have tagged TurtleTerm releases, verified macOS and Linux dependency lists, Homebrew audit pass, bottle CI, and documented upgrade and rollback path.

## Why Homebrew first

Homebrew works across macOS and Linux with one install vocabulary. It gives TurtleTerm one near-term package lane for developer workstations before we split into distro-native packages, Flatpak, AppImage, Windows packaging, or OS image integration.

## Acceptance criteria

v0 is complete when:

1. A local developer can run `brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb`.
2. `turtleterm` launches TurtleTerm.
3. `turtle-term paths` works after installation.
4. `turtle-term run -- echo hello` emits events and receipts.
5. `turtle-agentctl --stdio ping` works.
6. `sourceos-term paths` still works as a compatibility command.
7. Formula has clear caveats for profile installation.
8. Private runtime binaries are not exposed as public product commands.

v1 is complete when `SourceOS-Linux/homebrew-tap` exists, the formula is copied into `Formula/turtle-term.rb`, macOS and Linux CI test `brew install --HEAD turtle-term`, and README documents install, upgrade, uninstall, and profile activation.

v2 is complete when TurtleTerm release tags exist, the formula uses stable release tarballs with checksums, bottles are published for supported macOS/Linux targets, and `brew install turtle-term` no longer requires `--HEAD`.
