# Agent Harness Terminal Receipt Surface

Status: v0.1 planning baseline  
Owner plane: TurtleTerm governed operator surface  
Consumers: SourceOS spec, AgentPlane, Policy Fabric, Memory Mesh, SCOPE-D, Delivery Excellence

## Purpose

This document defines the TurtleTerm receipt boundary for agent-harness operator work. The surface is intended to make sessions visible, bounded, policy-referenced, and replayable without assigning independent authority to agents or cognition layers.

## Boundary

TurtleTerm owns the local operator experience, wrapper receipts, approval receipts, pane references, local gateway evidence, and replayable workflow records.

TurtleTerm does not own AgentPlane graph execution, Policy Fabric authority decisions, Agent Machine provider lifecycle, Delivery Excellence scoreboards, Memory Mesh artifact storage, or SCOPE-D exercise execution.

## Receipt classes

TerminalSessionReceipt records a governed session with session id, actor ref, workspace ref, profile refs, policy admission ref, AgentPlane refs, timestamps, pane refs when applicable, and environment profile hash.

CommandReceipt records an execution event with event id, session ref, event hash, working directory, environment hash, artifact pointer refs, exit code, duration, policy decision ref, side-effect class, and replay eligibility.

MutationReceipt records an observed change with change id, execution ref, change class, target scope, run mode, policy decision ref, human-control event ref when required, before and after artifact refs when available, rollback ref, and denied operation refs.

OperatorApprovalReceipt records a typed human decision with approval id, actor ref, subject ref, decision, reason, timestamp, policy gate ref, AgentPlane ref, and Delivery Excellence human-control event ref.

## Integration notes

AgentPlane should cite TurtleTerm receipts in run, replay, session, evidence, diagnosis, and promotion surfaces.

Large outputs, transcripts, generated files, diffs, and local artifacts should be represented through Memory Mesh ArtifactPointer refs when large, sensitive, replay-critical, or customer-proof relevant.

Delivery Excellence should consume derived readouts such as success or failure, policy-blocked counts, change posture, approval latency, replay eligibility, operator intervention count, workflow cycle time, and customer-safe proof of work. It should not consume raw local transcripts unless policy permits it.

SCOPE-D should validate the governed-workflow boundary and provide checks that the policy reference model is preserved.

## Non-negotiables

- TurtleTerm must not grant ambient authority to agents.
- Agent Machine owns machine-local provider lifecycle.
- Policy Fabric decides controlled action authority.
- Outputs may require redaction and artifact pointers.
- Host-level changes must be explicit, policy-referenced, and rollback-aware.
- Human approvals are typed control events, not freeform notes.
- Delivery Excellence receives metrics and readouts, not uncontrolled raw logs.

## Near-term implementation path

1. Align wrapper receipts with SourceOS execution receipt boundaries.
2. Add examples for session, execution, change, and approval receipts.
3. Add a verifier requiring policy refs for controlled action classes.
4. Add Delivery Excellence projection examples.
5. Add SCOPE-D boundary checks for the governed operator workflow.
