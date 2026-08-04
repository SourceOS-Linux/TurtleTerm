# TurtleTerm and Agent Machine Integration

## Decision

TurtleTerm integrates with Agent Machine as a local and clustered runtime substrate, not as a competing runtime manager.

Agent Machine owns the machine-local runtime layer: hardware/runtime probing, inference provider lifecycle, model residency, cache-aware scheduling facts, AgentPod envelopes, governed side-effect boundaries, activation decisions, and execution receipts that upstream AgentPlane and Policy Fabric can verify.

TurtleTerm owns the operator terminal/session surface: profile selection, pane/session context, command proposals, policy prompts, terminal receipts, Neovim/tmux context, cloudfog surface selection, and agent handoff UX.

## Boundary

TurtleTerm asks Agent Machine:

- what runtime surfaces are available
- what AgentPods can be rendered
- what local inference routes exist
- what model/cache/provider facts are available
- whether an activation decision is allowed
- where a workload can run safely
- what runtime evidence or receipts were emitted

Agent Machine returns:

- machine probe facts
- runtime/provider availability
- AgentPod render output
- activation decisions
- storage receipts
- runtime evidence
- execution receipt references

TurtleTerm must not start runtime providers directly when Agent Machine activation gates exist.

## Flow

```text
TurtleTerm user or agent request
  -> turtle-agentd normalizes request
  -> Agent Registry resolves agent/skill identity
  -> Policy Fabric evaluates side-effect and surface policy
  -> Agent Machine probes/renders/evaluates runtime substrate
  -> AgentPlane receives evidence when execution is promoted
  -> TurtleTerm displays status, receipts, and replay references
```

## Runtime surface classes

TurtleTerm should expose Agent Machine surfaces as profiles:

```text
Local Host
Agent Machine Devshell
AgentPod: local-podman
AgentPod: model-provider
AgentPod: policy-sandbox
AgentPod: evidence-runner
Cluster Node
```

Each surface should map to an ExecutionSurface-like record with:

- surface id
- workspace id
- runtime kind
- provider id
- model/cache facts
- policy profile
- agent grant
- activation decision
- receipt requirement

## Operator UX

TurtleTerm should make Agent Machine feel like a normal terminal profile while showing trust metadata:

```text
🐢 repo [agent-machine/local-podman] policy:ask receipts:on
```

The user should be able to inspect a surface before opening it:

```bash
turtle-agentctl surfaces
turtle-agentctl inspect-surface agent-machine/local-podman
turtle-agentctl request-execution --surface agent-machine/local-podman -- make test
```

## Governed web acquisition

Agent Machine exposes **web acquisition** as a first-class governed capability — the `acquire`
built-in tool (advertised via Agent Machine's `/api/status` tool list, and over the Noetica MCP).
It fetches or crawls a URL through the governed acquisition plane (policy → robots → rate →
reputation → provenance → optional SynapseIQ enrichment → sink) and lands the result as evidence.
TurtleTerm surfaces it through the same boundary as any other side effect — it does not fetch.

Side-effect class: `network_call`; capability requirement: `net`. Because it egresses, Policy Fabric
admission and the Agent Registry grant are mandatory, and the request fails closed when no acquisition
worker is configured (`ACQUIRE_WORKER_URL` unset → 503, recorded as a failed governed run).

```text
TurtleTerm user or agent asks to acquire a URL
  -> turtle-agentd normalizes the request (surface, session, pane context)
  -> Agent Registry resolves the `acquire` tool identity + grant
  -> Policy Fabric evaluates the network_call side effect + egress policy
  -> Agent Machine runs the governed acquisition (POST /api/acquire → worker)
  -> a governed run + provenance receipt are emitted (streamed to /api/governance)
  -> TurtleTerm displays status, the provenance receipt, and the replay reference
```

```bash
# inspect the capability, then request a governed acquisition through the surface
turtle-agentctl inspect-tool acquire
turtle-agentctl request-execution --surface agent-machine/local-podman -- \
  acquire --url https://example.com --account sovereign --tier T1
```

The landed document carries its provenance (content hash, tier, posture, egress) into whichever sink
the estate configured — the Prophet Mesh evidence store, the local ledger, or the workspace note
inbox (GooseNotes) — so the terminal receipt cross-links to the same evidence record. Surfacing this
as a native command/profile in the TurtleTerm UI (command palette entry, receipt rendering) is
TurtleTerm-side work; the capability, its governance, and its receipts already exist in Agent Machine.

## Non-goals

- TurtleTerm does not own runtime placement.
- TurtleTerm does not own provider activation.
- TurtleTerm does not own model residency.
- TurtleTerm does not bypass Policy Fabric admission.
- TurtleTerm does not bypass Agent Registry grants.
- TurtleTerm does not replace AgentPlane evidence.
