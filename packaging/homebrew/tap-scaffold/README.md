# SourceOS-Linux/homebrew-tap

This directory contains the files needed to bootstrap the `SourceOS-Linux/homebrew-tap` repository.

## Setup

1. Create a new **public** GitHub repository named `homebrew-tap` under the `SourceOS-Linux` organization.
2. Copy the contents of this `tap-scaffold/` directory into the root of that repo.
3. Push to `main`.
4. Users can then install with:

```bash
brew tap SourceOS-Linux/tap
brew install turtle-term
```

## Structure

```
homebrew-tap/
  Formula/
    turtle-term.rb    # Stable release formula (HEAD points at main; stable points at a release tag)
  README.md
```

## After cutting a release

When `turtle-term-v0.1.0` is published on GitHub Releases:

1. Copy the release tarball URL and its SHA-256 into `Formula/turtle-term.rb`.
2. Update the `version` field.
3. Commit and push to `main` on the tap repo.
4. Build and publish bottles (see RELEASE_RUNBOOK.md).
