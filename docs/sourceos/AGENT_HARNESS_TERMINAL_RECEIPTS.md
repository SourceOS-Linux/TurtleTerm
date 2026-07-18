# Agent Harness Terminal Receipt Surface

Status: v0.1 planning baseline  
Owner plane: TurtleTerm governed terminal/operator surface  
Consumers: SourceOS spec, AgentPlane, Policy Fabric, Memory Mesh, SCOPE-D, Delivery Excellence

## Purpose

TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench. The Aden/Hive production-agent pattern requires terminal work to be visible, bounded, receipt-producing, and measurable. TurtleTerm should make terminal/operator execution auditable without granting ambient shell authority to agents or cognition layers.

## Boundary

TurtleTerm owns:

- terminal/session UX
- command wrapper behavior
- local agent gateway surface
- terminal receipts
- operator approval surfaces
- tmux/mux bridge receipts
- skill manifests for terminal operations
- replayable operator workflows

TurtleTerm does not own:

- AgentPlane graph execution
- Policy Fabric gate authority
- Agent Machine runtime provider lifecycle
- Delivery Excellence scoreboards
- Memory Mesh artifact storage
- SCOPE-D security exercise execution

## Receipt classes

### TerminalSessionReceipt

Records an operator or agent-addressable terminal session.

Required semantics:

- terminal session id
- actor/agent ref
- workspace ref
- shell profile
- gateway profile
- policy admission ref
- AgentPlane run/session refs
- start/end timestamps
- mux/tmux pane refs when applicable
- environment profile hash

### CommandReceipt

Records a command execution through TurtleTerm.

Required semantics:

- command id
- terminal session ref
- command hash
- command display text when policy permits
- working directory
- environment profile hash
- stdin/stdout/stderr artifact pointer refs
- exit code
- duration
- policy decision ref
- side-effect class
- replay eligibility

### MutationReceipt

Records observed filesystem, process, deployment, or host mutation.

Required semantics:

- mutation id
- command ref
- mutation class
- target scope
- dry-run/live-run mode
- policy decision ref
- human-control event ref when required
- before/after artifact refs when available
- rollback ref
- denied operation refs

### OperatorApprovalReceipt

Records human operator decisions in TurtleTerm.

Required semantics:

- approval id
- actor ref
- subject ref
- decision
- reason
- timestamp
- policy gate ref
- AgentPlane run/session ref
- Delivery Excellence human-control event ref

## Controlled actions

Require Policy Fabric decisions for:

- package install
- filesystem mutation outside workspace scope
- deployment/apply operations
- service start/stop/restart
- network listener creation
- secret/key material access
- credential helper invocation
- privilege escalation
- destructive command patterns
- host mutation
- cluster mutation

Fail closed when controlled actions lack a policy decision ref.

## AgentPlane integration

AgentPlane should cite TurtleTerm receipts in:

- RunArtifact
- ReplayArtifact
- SessionEnvelope
- EvidencePack
- FailureDiagnosis
- PromotionGate

TurtleTerm receipts should preserve enough evidence for replay, diagnosis, and customer-safe proof without exposing raw secrets.

## Memory Mesh integration

Large stdout/stderr, shell transcripts, generated files, diffs, and terminal artifacts should be moved behind Memory Mesh `ArtifactPointer` refs when large, sensitive, replay-critical, or customer-proof relevant.

## Delivery Excellence integration

Delivery Excellence should consume derived metrics/readouts:

- command success/failure
- policy-blocked command count
- host mutation denied/approved/performed
- approval latency
- replay-eligible command count
- operator intervention count
- terminal workflow cycle time
- customer-safe proof of operator work

Delivery Excellence should not consume raw terminal transcripts unless policy explicitly permits it.

## SCOPE-D integration

SCOPE-D should validate TurtleTerm workflows for:

- command injection
- shell escape
- destructive command bypass
- privilege escalation
- secret exfiltration
- unauthorized filesystem mutation
- unauthorized service exposure
- hostile generated scripts
- host/cluster mutation bypass

## Non-negotiables

- TurtleTerm must not grant ambient shell authority to agents.
- Agent Machine owns machine-local runtime provider lifecycle.
- Policy Fabric decides controlled action authority.
- Command outputs may need redaction and artifact pointers.
- Host mutation must be explicit, policy-referenced, and rollback-aware.
- Human approvals are typed control events, not freeform notes.
- Delivery Excellence receives metrics and readouts, not uncontrolled shell logs.

## Near-term implementation path

1. Align TurtleTerm command wrapper receipts with SourceOS `ShellReceiptEvent` and SourceOS execution receipt boundaries.
2. Add examples for terminal session, command, mutation, and operator approval receipts.
3. Add a verifier requiring policy refs for controlled action classes.
4. Add Delivery Excellence projection examples for command success, mutation posture, and approval latency.
5. Add SCOPE-D terminal-risk checks for command injection, secret access, host mutation, and shell escape.
