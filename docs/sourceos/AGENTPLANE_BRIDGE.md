# TurtleTerm AgentPlane Bridge

## Purpose

AgentPlane owns evidence-producing execution. TurtleTerm should promote terminal/session work into AgentPlane bundles when execution needs deterministic validation, placement, run, evidence, and replay.

## Bridge flow

```text
TurtleTerm session or command proposal
  → create AgentPlane bundle
  → validate bundle
  → select executor
  → run bundle
  → collect evidence artifacts
  → link artifacts to TurtleTerm receipt
```

## AgentPlane artifacts

TurtleTerm should link or embed references to:

- ValidationArtifact
- PlacementDecision
- RunArtifact
- ReplayArtifact
- PromotionArtifact
- ReversalArtifact
- SessionArtifact

## Candidate commands

```bash
turtle-agentplane create-bundle --session <session-id>
turtle-agentplane validate <bundle>
turtle-agentplane run <bundle>
turtle-agentplane attach-artifacts --session <session-id> --artifacts <dir>
```

## When to use AgentPlane

- agent execution beyond human-mediated terminal capture
- high-risk host execution
- CI/release actions
- networked execution
- reproducibility required
- rollback/replay required
- policy obligations require evidence

## Non-goals

- replacing AgentPlane runners
- bypassing AgentPlane validation
- hiding failed evidence gates
