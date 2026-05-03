# TurtleTerm Browser Handoff

## Purpose

TurtleTerm does not own browser automation. BearBrowser owns browser tasks, including Stagehand and Playwright lanes.

TurtleTerm should hand off browser-relevant work to BearBrowser through registered skills and policy-gated A2A/MCP flows.

## Handoff flow

```text
terminal task needs browser work
  → TurtleTerm detects or user requests browser handoff
  → Agent Registry resolves BearBrowser skill
  → Policy Fabric evaluates handoff
  → A2A delegates task to BearBrowser agent
  → MCP exposes browser tools/resources where needed
  → BearBrowser returns receipt/artifacts
  → TurtleTerm links receipt to terminal session
```

## Candidate skills

- `turtle-bearbrowser-handoff`
- `turtle-playwright-mcp-handoff`
- `turtle-stagehand-handoff`

## Use cases

- log into developer portal
- inspect web documentation
- run browser-based workflow
- extract browser result into terminal task
- attach browser receipt to terminal session

## Non-goals

- embedding browser automation in TurtleTerm core
- bypassing BearBrowser
- direct browser control without policy
