# TurtleTerm Release Status

## Current objective

Make TurtleTerm easy to install and verify on macOS and Linux.

Windows packaging is postponed until the macOS/Linux distribution lane is stable.

## Current public install paths

### Tapless Homebrew HEAD install

```bash
brew install --HEAD https://raw.githubusercontent.com/SourceOS-Linux/wezterm/main/packaging/homebrew/Formula/turtle-term.rb
```

### Future tap install

```bash
brew install SourceOS-Linux/tap/turtle-term
```

Blocked until `SourceOS-Linux/homebrew-tap` exists.

### Future direct artifact install

```bash
curl -fsSL https://raw.githubusercontent.com/SourceOS-Linux/wezterm/main/packaging/scripts/install-turtle-term.sh | bash
```

Blocked until the first `turtle-term-v*` release publishes artifacts.

## Release readiness matrix

| Lane | Status | Notes |
| --- | --- | --- |
| TurtleTerm branding | Ready | README, formula, tests, and wrappers use TurtleTerm. |
| WezTerm attribution | Ready | License and upstream engine attribution preserved. |
| CLI wrappers | Ready for CI | `turtle-term` and `sourceos-term` both tested. |
| Tapless Homebrew formula | Ready for CI | Raw formula install path documented. |
| Public Homebrew tap | Blocked | Requires `SourceOS-Linux/homebrew-tap` repository. |
| Release tarballs | Ready for CI | Release workflow builds macOS/Linux targets. |
| Checksums | Ready for CI | Package script emits SHA-256 files. |
| Manifests | Ready for CI | Package script emits release manifest JSON. |
| Artifact verification | Ready for CI | Verifier checks archive, checksum, manifest, binaries, profile, docs, license. |
| SBOM | Ready for CI | Release workflow emits SPDX JSON SBOM. |
| Attestations | Ready for CI | Release workflow attests artifacts and SBOM. |
| Bottles | Scaffolded | Tap workflow exists; bottle publication still needs tap CI validation. |
| Security policy | Ready | `SECURITY.md` added. |
| Dependency updates | Ready | Dependabot covers GitHub Actions and Cargo weekly. |
| Windows packaging | Deferred | Candidate lanes: Chocolatey, WinGet, Scoop. |

## Hard blockers

1. `SourceOS-Linux/homebrew-tap` does not exist yet.
2. GitHub Actions results have not been confirmed green from this assistant session.
3. No `turtle-term-v*` release tag has been cut yet.
4. No bottles have been published yet.

## Next publish sequence

1. Confirm CI on `SourceOS-Linux/wezterm` is green.
2. Create or sync `SourceOS-Linux/homebrew-tap`.
3. Confirm `brew install --HEAD SourceOS-Linux/tap/turtle-term` works on supported macOS/Linux targets.
4. Cut `turtle-term-v0.1.0`.
5. Confirm tarballs, checksums, manifests, SBOMs, and attestations are published.
6. Promote a stable Homebrew formula from the release tag.
7. Build and publish Homebrew bottles.

## Definition of world-class v0

TurtleTerm v0 is world-class enough to publish when a user can install it with one command, verify what was installed, inspect provenance, and run:

```bash
turtle-term run -- echo turtle-term-ok
```

without needing to clone the repo or understand SourceOS internals.
