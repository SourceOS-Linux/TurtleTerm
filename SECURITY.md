# TurtleTerm Security Policy

## Scope

TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench for trusted command execution, terminal receipts, agent delegation, and reproducible operator workflows.

Security-sensitive areas include:

- terminal command execution
- `turtleterm`, `turtle-term`, and `sourceos-term` wrappers
- `turtle-agentd` local gateway
- `turtle-agentctl` command interface
- `turtle-tmux` bridge
- SourceOS terminal event and receipt generation
- release packaging and installer scripts
- Homebrew formulae and tap automation
- GitHub Actions release workflows
- artifact checksums, manifests, SBOMs, and attestations
- third-party notice and private runtime packaging boundaries

## Supported versions

Before the first stable release, only `main` and tagged `turtle-term-v*` release candidates are supported.

After stable release begins, this file should be updated with a supported-version table.

## Reporting a vulnerability

Do not open a public issue for a vulnerability.

Use GitHub private vulnerability reporting if available on this repository. If private reporting is not available, contact the repository maintainers directly and include:

- affected commit or release tag
- platform and install path
- reproduction steps
- expected behavior
- observed behavior
- impact assessment
- whether secrets, command execution, or user files are exposed

## Security expectations

TurtleTerm must not grant agents ambient shell authority.

Agent-facing terminal capabilities must be mediated through explicit SourceOS policy grants. Inspection, summarization, command proposal, command execution, attachment, artifact creation, pull request opening, and handoff should remain distinct grants.

## Release security posture

Release artifacts should include:

- tarball
- SHA-256 checksum
- release manifest JSON
- SPDX JSON SBOM
- GitHub artifact attestations
- third-party notices

Release workflows should verify artifacts before publishing them.

## Runtime and notices

TurtleTerm presents TurtleTerm product commands and stores private terminal runtime files outside the public command path. Required third-party notices and license attribution are preserved in `LICENSE.md`, `THIRD_PARTY_NOTICES.md`, and release artifacts.
