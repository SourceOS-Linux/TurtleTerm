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
7. Confirm script checks exist at `.github/workflows/turtle-term-scripts.yml`.
8. Run the SourceOS wrapper smoke test locally or in CI:

```bash
python3 assets/sourceos/tests/test_sourceos_term_smoke.py
```

9. Run local Homebrew install validation:

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
packaging/homebrew/.github/workflows/bottle-formula.yml -> .github/workflows/bottle-formula.yml
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
- macOS Intel tarball
- Linux x86_64 tarball
- Linux ARM64 tarball
- SHA-256 checksum files

Artifacts are attached to the GitHub release for the tag.

## Stable Homebrew formula promotion

After a release tag exists, render a stable formula from the release source archive SHA:

```bash
python3 packaging/scripts/render-stable-homebrew-formula.py turtle-term-v0.1.0 <source_sha256>
```

The workflow `.github/workflows/turtle-term-promote-homebrew-stable.yml` can compute the source archive SHA and sync the stable formula to the tap when `TURTLE_TERM_TAP_TOKEN` is configured.

## Bottle milestone

After HEAD formula CI is green on macOS and Linux, build Homebrew bottles in the tap.

The staged tap workflow is:

```text
packaging/homebrew/.github/workflows/bottle-formula.yml
```

The goal is to move from source builds to fast installs:

```bash
brew install turtle-term
```

## Acceptance criteria for v0 public availability

1. `brew install --HEAD SourceOS-Linux/tap/turtle-term` works on macOS ARM64.
2. `brew install --HEAD SourceOS-Linux/tap/turtle-term` works on macOS Intel.
3. `brew install --HEAD SourceOS-Linux/tap/turtle-term` works on Linux x86_64.
4. `brew install --HEAD SourceOS-Linux/tap/turtle-term` works on Linux ARM64.
5. `turtle-term paths` works.
6. `turtle-term run -- echo hello` emits events and receipts.
7. `sourceos-term paths` still works.
8. A `turtle-term-v0.1.0` release publishes tarballs and checksums.
9. README and formula both use TurtleTerm as the public product name.

## Post-v0 hardening

1. Add stable release tarball URL and SHA-256 to the formula.
2. Publish bottles.
3. Add upgrade/rollback docs.
4. Add Chocolatey, WinGet, or Scoop planning for Windows.
5. Add distro-native packaging for SourceOS Linux images.
