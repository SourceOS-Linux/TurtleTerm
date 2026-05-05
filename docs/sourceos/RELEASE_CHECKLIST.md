# TurtleTerm Release Checklist

## Goal

Publish TurtleTerm so Linux users can install, launch, verify, and audit it easily.

TurtleTerm is Linux-first. macOS remains a compatibility lane, but macOS signing, notarization, DMG/PKG packaging, and Gatekeeper validation are deferred.

Primary Linux install lanes:

```bash
brew install SourceOS-Linux/tap/turtle-term
```

```bash
sudo dpkg -i turtle-term_<version>_<arch>.deb
```

```bash
sudo rpm -i turtle-term-<version>-*.rpm
```

```bash
sudo pacman -U turtle-term-<version>-1-<arch>.pkg.tar.zst
```

Windows packaging is postponed.

## Pre-release validation

1. Confirm the repo README presents TurtleTerm as the product.
2. Confirm `LICENSE.md` and `THIRD_PARTY_NOTICES.md` are present.
3. Confirm stale `sourceos-wezterm.rb` formula is absent.
4. Confirm the release workflow exists at `.github/workflows/turtle-term-release.yml`.
5. Confirm the native Linux package workflow exists at `.github/workflows/turtle-term-native-linux-packages.yml`.
6. Confirm the Linux packaging validation workflow exists at `.github/workflows/turtle-term-linux-packaging.yml`.
7. Confirm script checks exist at `.github/workflows/turtle-term-scripts.yml`.
8. Run local product and package guards:

```bash
python3 assets/sourceos/tests/test_sourceos_term_smoke.py
python3 assets/sourceos/tests/test_turtle_product_identity.py
python3 assets/sourceos/tests/test_turtle_linux_desktop_identity.py
python3 assets/sourceos/tests/test_turtle_linux_native_packaging.py
python3 assets/sourceos/tests/test_turtle_neovim_integration.py
python3 assets/sourceos/tests/test_turtle_term_release_readiness.py
```

9. Run Linux package layout validation:

```bash
bash packaging/scripts/verify-linux-package-layout.sh
bash packaging/scripts/verify-deb-package.sh
bash packaging/scripts/verify-rpm-package.sh
bash packaging/scripts/verify-arch-package.sh
```

10. Run local Homebrew install validation where Homebrew is available:

```bash
brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb
brew test turtle-term
turtleterm --version || true
turtle-term run -- echo turtle-term-ok
turtle-agentctl --stdio ping
```

## Release artifact publication

Tag the release from `main`:

```bash
git tag turtle-term-v0.1.0
git push origin turtle-term-v0.1.0
```

The release workflows should publish:

- Linux x86_64 tarball
- Linux ARM64 tarball
- macOS ARM64 tarball, unsigned compatibility artifact
- macOS Intel tarball, unsigned compatibility artifact
- Debian packages for amd64 and arm64
- RPM packages for x86_64 and aarch64
- Arch packages for x86_64 and aarch64
- SHA-256 checksum files
- Package manifest JSON files
- Native package index JSON
- SPDX SBOMs
- GitHub artifact attestations

Every tarball should have:

```text
*.tar.gz
*.tar.gz.sha256
*.tar.gz.manifest.json
```

Every native package should have:

```text
*.deb | *.rpm | *.pkg.tar.zst
*.sha256
*.manifest.json
```

The native package set should have:

```text
turtle-term-native-packages.index.json
turtle-term-native-packages.index.json.sha256
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
turtleterm --version || true
turtle-term run -- echo turtle-term-ok
```

## Stable Homebrew formula promotion

After a release tag exists, render a stable formula from the release source archive SHA:

```bash
python3 packaging/scripts/render-stable-homebrew-formula.py turtle-term-v0.1.0 <source_sha256>
```

The workflow `.github/workflows/turtle-term-promote-homebrew-stable.yml` can compute the source archive SHA and sync the stable formula to the tap when `TURTLE_TERM_TAP_TOKEN` is configured.

## Acceptance criteria for v0 public availability

1. `turtleterm` launches TurtleTerm.
2. `turtle-term run -- echo turtle-term-ok` emits events and receipts.
3. `turtle-agentctl --stdio ping` works.
4. Linux desktop metadata validates.
5. AppStream metadata validates.
6. Debian, RPM, and Arch packages build with private runtime under `/usr/libexec/turtle-term`.
7. Native packages install the profile at `/etc/turtle-term/turtleterm.lua`.
8. Native package wrappers do not contain buildroot paths.
9. Native packages include checksums and manifests.
10. Native package index is published and attested.
11. Release tarballs include checksums, manifests, SBOMs, and attestations.
12. README, formulae, metadata, and packages use TurtleTerm as the public product name.

## Post-v0 hardening

1. Publish Homebrew bottles.
2. Add repository metadata for apt/yum/dnf/pacman distribution channels.
3. Add upgrade/rollback docs.
4. Add SourceOS image integration.
5. Add Windows packaging plan.
6. Revisit macOS signing/notarization after Linux distribution is stable.
