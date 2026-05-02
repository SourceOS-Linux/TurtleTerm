# SourceOS WezTerm Homebrew Packaging

This directory stages the Homebrew packaging lane for SourceOS Terminal Workbench.

The final tap should live in:

```text
SourceOS-Linux/homebrew-tap
```

Until that tap exists, developers can test the formula directly from this repository.

## Local install from this repository

```bash
git clone https://github.com/SourceOS-Linux/wezterm.git
cd wezterm
brew install --HEAD ./packaging/homebrew/Formula/sourceos-wezterm.rb
```

## Local reinstall while iterating

```bash
brew uninstall sourceos-wezterm || true
brew install --HEAD ./packaging/homebrew/Formula/sourceos-wezterm.rb
```

## Test installed wrapper

```bash
sourceos-term paths
sourceos-term run -- echo hello
```

## Activate the SourceOS WezTerm profile

The formula installs the SourceOS profile under Homebrew `etc`.

```bash
ln -sf "$(brew --prefix)/etc/sourceos/wezterm/wezterm.lua" ~/.wezterm.lua
```

Then launch:

```bash
wezterm-gui
```

## Future tap install flow

After `SourceOS-Linux/homebrew-tap` exists and the formula is copied to `Formula/sourceos-wezterm.rb`:

```bash
brew tap SourceOS-Linux/tap
brew install --HEAD sourceos-wezterm
```

After tagged releases and bottles exist:

```bash
brew install sourceos-wezterm
```

## Formula responsibilities

The formula installs:

- `wezterm`
- `wezterm-gui`
- `wezterm-mux-server`
- `sourceos-term`
- SourceOS WezTerm Lua profile
- SourceOS terminal documentation

## Current status

This is an experimental source-build formula. It is meant to prove macOS/Linux installation before release tarballs, checksums, and bottles exist.

Windows packaging is postponed. The likely Windows lane is Chocolatey, WinGet, or Scoop after Homebrew is stable.
