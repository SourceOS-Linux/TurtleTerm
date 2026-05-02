# TurtleTerm Release Checklist

## Goal

Publish TurtleTerm so users can install it easily on macOS and Linux.

The intended public path is:

```bash
brew install SourceOS-Linux/tap/turtle-term
```

Windows packaging is postponed until the Homebrew lane is stable.

## Pre-release validation

1. Confirm the repo README introduces TurtleTerm and preserves WezTerm attribution.
2. Confirm `LICENSE.md` is present.
3. Confirm the Homebrew formula is `packaging/homebrew/Formula/turtle-term.rb`.
4. Confirm the stale `sourceos-wezterm.rb` formula is absent.
5. Confirm the release workflow exists at `.github/workflows/turtle-term-release.yml`.
6. Confirm the Homebrew validation workflow exists at `.github/workflows/turtle-term-homebrew.yml`.
7. Run the SourceOS wrapper smoke test locally or in CI:

```bash
python3 assets/sourceos/tests/test_sourceos_term_smoke.py
```

8. Run local Homebrew install validation:

```bash
brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb
brew test turtle-term
turtle-term run -- echo turtle-term-ok
```

## First public tap release

Create `SourceOS-Linux/homebrew-tap` if it does not already exist.

Copy staged files into the tap:

```text
packaging/homebrew/Formula/turtle-term.rb -> Formula/turtle-term.rb
packaging/homebrew/README.md -> README.md
packaging/homebrew/.github/workflows/test-formula.yml -> .github/workflows/test-formula.yml
```

Push the tap.

Validate public install:

```bash
brew install --HEAD SourceOS-Linux/tap/turtle-term
turtle-term run -- echo turtle-term-ok
```

## Release artifact publication

Tag the release from `main`:

```bash
git tag turtle-term-v0.1.0
git push origin turtle-term-v0.1.0
```

The release workflow builds:

- macOS ARM64 tarball
- Linux x86_64 tarball
- SHA-256 checksum files

Artifacts are attached to the GitHub release for the tag.

## Bottle milestone

After HEAD formula CI is green on macOS and Linux, add Homebrew bottle automation in the tap.

The goal is to move from source builds to fast installs:

```bash
brew install turtle-term
```

## Acceptance criteria for v0 public availability

1. `brew install --HEAD SourceOS-Linux/tap/turtle-term` works on macOS.
2. `brew install --HEAD SourceOS-Linux/tap/turtle-term` works on Linux.
3. `turtle-term paths` works.
4. `turtle-term run -- echo hello` emits events and receipts.
5. `sourceos-term paths` still works.
6. A `turtle-term-v0.1.0` release publishes tarballs and checksums.
7. README and formula both use TurtleTerm as the public product name.

## Post-v0 hardening

1. Add stable release tarball URL and SHA-256 to the formula.
2. Publish bottles.
3. Add upgrade/rollback docs.
4. Add Chocolatey, WinGet, or Scoop planning for Windows.
5. Add distro-native packaging for SourceOS Linux images.
