# TurtleTerm Supply Chain

## Purpose

TurtleTerm release artifacts should be easy to install and easy to verify.

This document defines the current supply-chain posture for macOS and Linux distribution.

## Release artifact set

For each supported target, the release workflow publishes:

```text
turtle-term-<version>-<target>.tar.gz
turtle-term-<version>-<target>.tar.gz.sha256
turtle-term-<version>-<target>.tar.gz.manifest.json
turtle-term-<target>.spdx.json
```

Supported release targets:

- macOS ARM64
- macOS Intel
- Linux x86_64
- Linux ARM64

## Verification layers

### SHA-256 checksum

Each tarball has a checksum file.

### Release manifest

Each tarball has a TurtleTerm manifest with:

- product identity
- version
- target
- archive file name
- archive SHA-256
- license
- third-party notice reference
- public TurtleTerm commands
- private runtime path
- profile path
- docs path
- skill manifest path
- brand asset path
- install validation commands

### Artifact verifier

Use:

```bash
python3 packaging/scripts/verify-turtle-term-artifact.py turtle-term-<version>-<target>.tar.gz
```

The verifier checks:

- archive exists
- checksum exists
- manifest exists
- checksum matches archive
- manifest schema is expected
- product is TurtleTerm
- manifest archive hash matches
- TurtleTerm public commands are present
- private runtime binaries are not exposed on the product PATH
- license and third-party notice files are present
- TurtleTerm product profile is present
- TurtleTerm brand assets are present
- TurtleTerm skill manifests are present
- SourceOS documentation is present

### GitHub artifact attestations

Release artifacts are attested with GitHub Actions artifact attestations.

The workflow uses:

- `actions/attest@v4`
- `id-token: write`
- `attestations: write`
- `artifact-metadata: write`

### SBOM

The release workflow generates an SPDX JSON SBOM with Anchore's SBOM action and attests it with GitHub artifact attestations.

## Homebrew path

Homebrew is the preferred macOS/Linux installation path.

Current no-checkout install path:

```bash
brew install --HEAD https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/packaging/homebrew/Formula/turtle-term.rb
```

Future tap path:

```bash
brew install SourceOS-Linux/tap/turtle-term
```

## Third-party notices

Required third-party notices are preserved in `THIRD_PARTY_NOTICES.md` and release artifacts.

## Windows status

Windows packaging is postponed until macOS and Linux release/install lanes are stable.

Candidate future lanes:

- Chocolatey
- WinGet
- Scoop
