# SourceOS WezTerm Upstream Sync Policy

## Purpose

This fork should remain rebase-friendly.

SourceOS needs a terminal fabric, not an unmaintainable terminal fork. The default posture is to preserve upstream WezTerm architecture and layer SourceOS-specific behavior as opt-in profiles, documentation, sidecars, contracts, and namespaced integrations.

## Branch posture

Recommended long-lived branches:

| Branch | Purpose |
| --- | --- |
| `main` | SourceOS integration branch, kept close to upstream. |
| `sourceos/profile-pack` | SourceOS Lua config, themes, and desktop defaults. |
| `sourceos/session-contract` | Session contract and receipt documentation/schema work. |
| `sourceos/agent-bridge` | Sidecar and agent bridge experiments. |
| `sourceos/packaging` | SourceOS packaging and desktop integration. |

Avoid mixing cosmetic profile changes, contract changes, Rust internals, and packaging changes in one PR.

## Commit categories

Use clear prefixes:

| Prefix | Meaning |
| --- | --- |
| `sourceos-docs:` | SourceOS documentation only. |
| `sourceos-profile:` | SourceOS config/profile/theme changes. |
| `sourceos-contract:` | Session, receipt, schema, or evidence contract changes. |
| `sourceos-agent:` | Agent bridge or sidecar work. |
| `sourceos-policy:` | PolicyFabric or grant model integration. |
| `sourceos-packaging:` | Distro/package/deployment changes. |
| `upstream-fix:` | Patch that may be suitable for upstream WezTerm. |

## What belongs upstream

Prefer upstreamable patches for:

- generic terminal bugs
- rendering issues
- mux correctness fixes
- SSH/domain correctness fixes
- Wayland/X11 fixes
- docs fixes that apply to upstream WezTerm
- dependency/build fixes not specific to SourceOS

Keep such patches small and clean so they can be submitted upstream.

## What belongs only in SourceOS

Keep SourceOS-only changes namespaced and opt-in:

- SourceOS product planning
- SourceOS profile pack
- SourceOS policy grants
- SourceOS agent bridge
- SourceOS terminal session contract
- workstation-contract receipt integration
- Matrix/AgentTerm bridge conventions
- SourceOS packaging overlays
- SourceOS branding assets

## Naming rules

Use `sourceos` namespace for SourceOS-specific files, environment variables, config keys, event schemas, and local paths.

Examples:

```text
docs/sourceos/
assets/sourceos/
sourceos.terminal.session.v0
sourceos.terminal.event.v0
sourceos.terminal.receipt.v0
SOURCEOS_TERMINAL_SESSION_ID
SOURCEOS_TERMINAL_EVENTS
```

## Rebase discipline

Before pulling from upstream:

1. Record current SourceOS commit SHA.
2. Fetch upstream WezTerm.
3. Review upstream release notes and breaking changes.
4. Rebase or merge upstream into a temporary branch first.
5. Run build and smoke validation.
6. Verify SourceOS docs/profile files still exist.
7. Verify license files remain intact.
8. Only then update `main`.

Recommended remote layout for local clones:

```bash
git remote add upstream https://github.com/wez/wezterm.git
git fetch upstream
git checkout main
git checkout -b sourceos/sync-upstream-YYYYMMDD
git merge upstream/main
```

Use merge for lower-risk syncs when preserving SourceOS integration history matters. Use rebase only when the branch is private or explicitly coordinated.

## License discipline

Do not remove upstream `LICENSE.md`.

Do not remove upstream copyright.

Do not strip bundled font license notices.

SourceOS-specific files may add additional copyright/license headers if required, but they must not conflict with upstream MIT licensing for the forked work.

## Rust internals policy

Do not modify Rust internals until the sidecar/profile/contract path has been exhausted.

When Rust changes become necessary, isolate them by capability:

1. metadata exposure
2. event hooks
3. local sidecar transport
4. policy gate integration
5. command execution plumbing

Avoid broad refactors.

## Sidecar-first policy

The first SourceOS terminal integration should use sidecars and config/profile files where possible.

Preferred path:

1. SourceOS Lua profile pack.
2. Shell integration wrapper.
3. Local NDJSON event stream.
4. Receipt writer.
5. Agent bridge consuming event/receipt data.
6. Rust hooks only where profile/shell/sidecar mechanisms are insufficient.

## Review checklist

Every SourceOS PR should answer:

- Is this upstream-friendly or SourceOS-only?
- Does it preserve `LICENSE.md`?
- Does it preserve upstream attribution?
- Is it opt-in or does it alter default upstream behavior?
- Does it make future upstream sync harder?
- Is the change documented under `docs/sourceos/`?
- Does it keep agent execution behind explicit policy grants?
- Does it avoid granting ambient shell access to agents?

## v0 sync target

The v0 target is a clean fork with:

1. SourceOS product plan.
2. SourceOS session contract.
3. SourceOS upstream sync policy.
4. SourceOS profile pack.
5. No invasive Rust modifications unless justified by a concrete integration test.
6. A clear path to workstation-contract and AgentPlane integration.
