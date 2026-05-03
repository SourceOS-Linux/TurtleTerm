# TurtleTerm Agent Registry Bridge

## Purpose

TurtleTerm must never run unregistered agents.

The Agent Registry bridge resolves agent identity, provider identity, SkillManifest references, allowed execution surfaces, and policy bindings before TurtleTerm permits delegation or execution.

## Responsibilities

- resolve agent identity
- resolve provider/runtime identity
- resolve SkillManifest
- confirm allowed ExecutionSurface
- confirm policy bindings
- confirm shell execution permission
- confirm protected paths
- record agentRef and skillRef on receipts

## Required checks

Before delegation or execution:

1. agent is registered
2. skill is registered
3. execution surface is valid
4. policy binding exists
5. requested action matches skill activation rules
6. shell execution is allowed for the skill when applicable
7. protected paths are enforced

## Outputs

- agentRef
- skillRef
- providerRef
- executionSurfaceRef
- policyBindingRefs
- decision input for Policy Fabric

## Non-goals

- ad hoc unregistered agents
- runtime-only implicit trust
- bypassing Policy Fabric
