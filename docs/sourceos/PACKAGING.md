# SourceOS WezTerm Packaging Plan

## Purpose

Make SourceOS Terminal Workbench installable with Homebrew on macOS and Linux first.

Windows packaging is intentionally postponed. The expected Windows lane is Chocolatey or WinGet after the macOS/Linux Homebrew path is stable.

## Product package name

Recommended Homebrew formula name:

```text
sourceos-wezterm
```

This distinguishes the SourceOS terminal fabric from upstream WezTerm while preserving upstream attribution and license posture.

## Target install modes

### v0: Homebrew HEAD formula

Until SourceOS tags releases and publishes bottles, install from Git head:

```bash
brew install --HEAD sourceos-wezterm
```

For local development from this repository:

```bash
brew install --HEAD ./packaging/homebrew/Formula/sourceos-wezterm.rb
```

### v1: Homebrew tap

Create a dedicated tap repository:

```text
SourceOS-Linux/homebrew-tap
```

Expected tap layout:

```text
Formula/sourceos-wezterm.rb
README.md
.github/workflows/
```

Expected user flow:

```bash
brew tap SourceOS-Linux/tap
brew install --HEAD sourceos-wezterm
```

After tagged releases exist:

```bash
brew install sourceos-wezterm
```

### v2: Bottles

Once CI is stable, publish bottles for:

- macOS Apple Silicon
- macOS Intel if needed
- Linux x86_64
- Linux ARM64 if supported by CI/build dependencies

## What the formula should install

The Homebrew package should install:

- `wezterm`
- `wezterm-gui`
- `wezterm-mux-server`
- `sourceos-term`
- SourceOS WezTerm profile pack
- SourceOS terminal docs

Expected installed paths:

```text
$(brew --prefix)/bin/wezterm
$(brew --prefix)/bin/wezterm-gui
$(brew --prefix)/bin/wezterm-mux-server
$(brew --prefix)/bin/sourceos-term
$(brew --prefix)/etc/sourceos/wezterm/wezterm.lua
$(brew --prefix)/share/sourceos-wezterm/sourceos/
```

## Build posture

The current formula is experimental and source-build oriented.

It should remain `--HEAD` until we have:

1. tagged SourceOS releases,
2. verified macOS build dependency list,
3. verified Linux build dependency list,
4. Homebrew audit pass,
5. bottle CI,
6. documented upgrade and rollback path.

## Why Homebrew first

Homebrew works across macOS and Linux with one install vocabulary. It gives SourceOS one near-term package lane for developer workstations before we split into distro-native packages, Flatpak, AppImage, or OS image integration.

## Linux notes

Linux Homebrew is not the final SourceOS OS packaging strategy. It is the developer bootstrap strategy.

The eventual SourceOS Linux image/package lane should still support native packaging overlays and immutable OS integration.

## macOS notes

macOS support is important because current development workstations may be macOS while the target OS remains Linux-first.

The Homebrew formula should not require users to replace their existing terminal. It should install SourceOS Terminal Workbench as an additional toolchain surface.

## Windows postponed lane

Postponed candidates:

- Chocolatey
- WinGet
- Scoop
- MSI installer

Windows should not block macOS/Linux Homebrew readiness.

## Acceptance criteria

v0 is complete when:

1. A local developer can run `brew install --HEAD ./packaging/homebrew/Formula/sourceos-wezterm.rb`.
2. `sourceos-term paths` works after installation.
3. `sourceos-term run -- echo hello` emits events and receipts.
4. `wezterm --version` works after installation.
5. `wezterm-gui --version` works after installation where GUI dependencies are available.
6. Formula has clear caveats for profile installation.
7. The packaging lane does not modify WezTerm Rust internals.

v1 is complete when:

1. `SourceOS-Linux/homebrew-tap` exists.
2. Formula is copied into `Formula/sourceos-wezterm.rb`.
3. macOS and Linux CI test `brew install --HEAD sourceos-wezterm`.
4. README documents install, upgrade, uninstall, and profile activation.

v2 is complete when:

1. SourceOS release tags exist.
2. Formula uses stable release tarballs with SHA-256 checksums.
3. Bottles are published for supported macOS/Linux targets.
4. `brew install sourceos-wezterm` no longer requires `--HEAD`.
