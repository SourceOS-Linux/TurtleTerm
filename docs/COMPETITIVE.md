# TurtleTerm vs the AI-Terminal Field

> Honest head-to-head. We mark our own gaps, not just our wins — because overstating position is how you die in a demo. Competitor claims are current (2025–2026).

## The one-line pitch

**Faster than Warp. Local AI Warp can't match. Governed and replay-attestable like nothing else. And it does Warp's headline tricks too.**

We are not a "sovereign alternative to Warp" (defensive). We are a better AI terminal that also happens to be the only sovereign, governed, evidence-emitting one (offensive).

## Where we win on their own turf (the AI-terminal game)

| Advantage | Why it beats them |
|---|---|
| **Faster core** | WezTerm/WebGPU base out-renders Warp (~8ms latency) for free. Speed is table stakes and we already have it. |
| **Local / offline agent** | Full NL→shell, error-explain, and the autonomous loop run on Ollama or self-hosted Noetica — zero cloud. Warp Free can't run its agent without paying or BYOK. |
| **Always-on autosuggest, fully local** | Warp's most-demoed feature ("Next Command" ghost text) — ours, with no $20/mo credit meter and no telemetry. |
| **Native remote multiplexing** | WezTerm mux over SSH, no remote tmux. Warp has no remote mux. |
| **Self-hosted live session sharing** | Pair on a live terminal over the mux — no cloud account, no SaaS. |
| **Sovereign Warp Drive** | Workflows/runbooks/bookmarks unified, parameterized, and versioned in *your* Gitea forge — not a US cloud. |
| **Governed, replay-attestable agent** | Every agent action emits a spec-conformant `ReasoningRun/Event/Receipt/ReplayPlan`, policy-gated, destructive-by-default-deny, then sealed tamper-evident. **No competitor ships anything in this class.** |
| **Voice→shell, personas, AI coach, cost tracking** | Categories Warp/Wave/Cursor simply don't have. `turtle-cost` shows per-model spend vs Warp's opaque credit meter. |
| **Sovereign forge loop** | Gitea-primary PR/CI/review/AI-changelog, native — not routed through a cloud agent. |

## What we deliberately reject (don't chase)

- **Cloud-locked AI + telemetry-to-use-AI.** Warp's agents, Drive, and collaboration are a proprietary US cloud; on the Free plan, telemetry must be ON to use AI. We weaponize the *absence* of this, not replicate it.
- **Credit-metered AI ($20/mo, 1,500 credits).** Self-hosted means no meter. That's the pitch, not a feature to copy.

## Honest gaps we're closing

| Gap | Status |
|---|---|
| Inline always-on autosuggest polish | **Closing** — `predict_command` + shell ghost text (local, history-first) |
| Unified shareable workflow library (Warp Drive) | **Closing** — `turtle-drive`, Gitea-versioned |
| Real-time session sharing | **Closing** — `turtle-share` over WezTerm mux |
| UX polish / design-led onboarding | **Open** — our real gap; speed advantage is free, polish is earned |
| Teams / shared knowledge at org scale | **Partial** — `turtle-sync` + Gitea-versioned drive; no live team layer yet |

## The bottom line

Warp wins on polish and adoption. We win on speed, sovereignty, governance, and a set of capabilities (voice, personas, attestable agent loops, cost transparency, forge-native) they can't follow us into without rebuilding their cloud-locked foundation. The three kill-shots above (autosuggest, drive, share) erase the last reasons a buyer would still pick Warp — while the governance/replay moat stays uncontested.
