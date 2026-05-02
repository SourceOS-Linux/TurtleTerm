# TurtleTerm Packaging Plan

## Purpose

Make TurtleTerm installable with Homebrew on macOS and Linux first.

TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench product built on the WezTerm engine. We preserve upstream WezTerm attribution and licensing while exposing the SourceOS product as TurtleTerm.

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

### v2: Bottles

Once CI is stable, publish bottles for macOS Apple Silicon, macOS Intel if needed, Linux x86_64, and Linux ARM64 if supported by CI and build dependencies.

## What the formula should install

The Homebrew package should install:

- `wezterm`
- `wezterm-gui`
- `wezterm-mux-server`
- `turtle-term`
- `sourceos-term` compatibility command
- TurtleTerm / SourceOS WezTerm profile pack
- TurtleTerm / SourceOS terminal docs

Expected installed paths:

```text
$(brew --prefix)/bin/wezterm
$(brew --prefix)/bin/wezterm-gui
$(brew --prefix)/bin/wezterm-mux-server
$(brew --prefix)/bin/turtle-term
$(brew --prefix)/bin/sourceos-term
$(brew --prefix)/etc/turtle-term/wezterm.lua
$(brew --prefix)/share/turtle-term/sourceos/
```

## Build posture

The current formula is experimental and source-build oriented. It should remain `--HEAD` until we have tagged TurtleTerm releases, verified macOS and Linux dependency lists, Homebrew audit pass, bottle CI, and documented upgrade and rollback path.

## Why Homebrew first

Homebrew works across macOS and Linux with one install vocabulary. It gives TurtleTerm one near-term package lane for developer workstations before we split into distro-native packages, Flatpak, AppImage, Windows packaging, or OS image integration.

## Linux notes

Linux Homebrew is not the final SourceOS OS packaging strategy. It is the developer bootstrap strategy. The eventual SourceOS Linux image/package lane should still support native packaging overlays and immutable OS integration.

## macOS notes

macOS support is important because current development workstations may be macOS while the target OS remains Linux-first. The Homebrew formula should not require users to replace their existing terminal. It should install TurtleTerm as an additional toolchain surface.

## Windows postponed lane

Windows package candidates are postponed until the macOS/Linux Homebrew path is stable.

## Acceptance criteria

v0 is complete when:

1. A local developer can run `brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb`.
2. `turtle-term paths` works after installation.
3. `turtle-term run -- echo hello` emits events and receipts.
4. `sourceos-term paths` still works as a compatibility command.
5. `wezterm --version` works after installation.
6. `wezterm-gui --version` works after installation where GUI dependencies are available.
7. Formula has clear caveats for profile installation.
8. The packaging lane does not modify WezTerm Rust internals.

v1 is complete when `SourceOS-Linux/homebrew-tap` exists, the formula is copied into `Formula/turtle-term.rb`, macOS and Linux CI test `brew install --HEAD turtle-term`, and README documents install, upgrade, uninstall, and profile activation.

v2 is complete when TurtleTerm release tags exist, the formula uses stable release tarballs with checksums, bottles are published for supported macOS/Linux targets, and `brew install turtle-term` no longer requires `--HEAD`.
