# TurtleTerm Homebrew Tap Handoff

## Goal

Move TurtleTerm from local formula staging to public Homebrew installation.

Target install path:

```bash
brew install SourceOS-Linux/tap/turtle-term
```

Or, after the tap is added:

```bash
brew tap SourceOS-Linux/tap
brew install turtle-term
```

## Required tap repository

Homebrew expects a GitHub tap repository named:

```text
SourceOS-Linux/homebrew-tap
```

Homebrew maps `brew tap SourceOS-Linux/tap` to that repository.

## Files to copy into the tap

```text
packaging/homebrew/Formula/turtle-term.rb -> Formula/turtle-term.rb
packaging/homebrew/README.md -> README.md
packaging/homebrew/.github/workflows/test-formula.yml -> .github/workflows/test-formula.yml
```

## First public install test

After the tap repo exists:

```bash
brew install --HEAD SourceOS-Linux/tap/turtle-term
turtle-term run -- echo turtle-term-ok
```

## Release artifact path

The main `SourceOS-Linux/wezterm` repository builds release artifacts on tags matching:

```text
turtle-term-v*
```

Example release tag:

```bash
git tag turtle-term-v0.1.0
git push origin turtle-term-v0.1.0
```

The release workflow publishes macOS and Linux tarballs plus SHA-256 files to the GitHub release.

## Bottle path

Homebrew bottles should be added after the tap CI is green. The first milestone is source-build installability. The second milestone is bottles for fast customer installation.

## Acceptance criteria

1. `SourceOS-Linux/homebrew-tap` exists.
2. `brew install --HEAD SourceOS-Linux/tap/turtle-term` works on macOS.
3. `brew install --HEAD SourceOS-Linux/tap/turtle-term` works on Linux.
4. `turtle-term run -- echo hello` emits events and receipts.
5. Release tag `turtle-term-v0.1.0` publishes tarballs.
6. Bottles are published after CI proves repeatability.

## Windows status

Windows packaging remains postponed. The likely follow-on lanes are Chocolatey, WinGet, and Scoop, but they should not block macOS/Linux Homebrew availability.
