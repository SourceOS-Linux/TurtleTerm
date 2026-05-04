# TurtleTerm Linux Native Packaging

TurtleTerm is Linux-first. This directory stages native Linux package metadata after Homebrew and release tarball install paths.

## Current package scaffolds

- `deb/control`
- `rpm/turtle-term.spec`
- `arch/PKGBUILD`

## Shared package layout

All native package lanes should use:

```bash
packaging/scripts/stage-linux-package.sh
```

The staged layout includes:

```text
bin/turtleterm
bin/turtleterm-mux-server
bin/turtle-term
bin/turtle-agentd
bin/turtle-agentctl
bin/turtle-tmux
bin/sourceos-term
etc/turtle-term/turtleterm.lua
libexec/turtle-term/
share/applications/ai.sourceos.TurtleTerm.desktop
share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml
share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg
share/turtle-term/
```

## Validation

Run:

```bash
packaging/scripts/verify-linux-package-layout.sh
```

The verifier stages the package layout with stub runtime binaries and checks public commands, private runtime isolation, metadata, profile, and agent CLI behavior.

## Not done yet

- Real `.deb` build workflow
- Real `.rpm` build workflow
- Real Arch package build workflow
- Release checksums for Arch source package
- SourceOS image integration
