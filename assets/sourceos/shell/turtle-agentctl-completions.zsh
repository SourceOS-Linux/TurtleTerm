#compdef turtle-agentctl
# TurtleTerm agent controller — zsh completions.
# Install: add the directory to fpath, or source this file from .zshrc.

_turtle_agentctl() {
  local state
  _arguments -C \
    '--stdio[Read one JSON request from stdin, write one JSON response]' \
    '--help[Show help message]' \
    '1: :_turtle_agentctl_cmds' \
    '*:: :->args'

  case $state in
    args)
      case $words[1] in
        plan|plan-execute)  _message 'goal: describe what you want to accomplish' ;;
        explain-selection|explain)  _message 'text: terminal output or selection to explain' ;;
        nl-to-shell|nl|voice-to-shell)  _message 'request: natural language description of shell command' ;;
        atlas-context|file-tree)  _files -/ ;;
        inspect|summarize|receipts|session-narrate|share-session)  _message 'session_id: terminal session ID (optional)' ;;
        noetica-query|memory-add|memory-search|memory-forget)  _message 'text: query or note text' ;;
        policy-evaluate-local|pre-exec-risk|shellcheck-lint)  _message 'command: shell command to evaluate' ;;
        bearbrowser-handoff)  _message 'task: browser task description to delegate to BearBrowser' ;;
        runbook-run|runbook-show)  _message 'name: runbook name from .turtle/runbooks/' ;;
        docker-exec|docker-logs)  _message 'container: container name or ID' ;;
        ssh-connect)  _message 'profile: SSH profile name from ssh-profiles' ;;
        sync-push|sync-pull)  _message '--remote URL: remote sync endpoint' ;;
        persona-set|persona-marketplace-install)  _message 'name: persona identifier' ;;
        output-export)  _message 'format: markdown, json, html, or gist' ;;
        plugin-install)  _message 'name: plugin name or URL' ;;
        sftp-browse|sftp-download)  _message 'host: SSH host or profile name' ;;
        team-config-set)  _message 'key=value: configuration key and value' ;;
        # Surface 2 — bg agent, webhooks, scratchpad, policy, hooks
        (bg-plan-start)   _message 'goal: describe what to do in the background' ;;
        (bg-plan-status)  _message 'plan_id: leave blank for most recent' ;;
        (bg-plan-cancel)  _message 'plan_id: ID from bg-plan-list' ;;
        (bg-plan-list)    # no args
            ;;
        (webhook-add)     _message 'url: https://your-endpoint/hook  [name]' ;;
        (webhook-remove)  _message 'url: webhook URL to remove' ;;
        (webhook-dispatch) _message 'event_type: e.g. command.completed' ;;
        (webhook-list)    # no args
            ;;
        (error-patterns)  _message 'threshold: minimum occurrence count (default 2)' ;;
        (scratchpad-write) _message 'content: text to save  [key: note name]' ;;
        (scratchpad-read) _message 'key: note name (default: default)' ;;
        (scratchpad-list) # no args
            ;;
        (policy-check)    _message 'command: shell command to check against .turtle/policy.yaml' ;;
        (install-hooks)   _message 'cwd: git repo path (default: current dir)' ;;
        (uninstall-hooks) _message 'cwd: git repo path (default: current dir)' ;;
        (dashboard)       # no args
            ;;
        # Forge / Gitea
        (gitea-status)    # no args
            ;;
        (gitea-repo-list) _message '[--limit N]' ;;
        (gitea-pr-create) _message '[--title "PR title"] [--base main]' ;;
        (gitea-pr-list)   _message '[--state open|closed|all]' ;;
        (gitea-issue-create) _message '[--title "title"] [--body "body"]' ;;
        (gitea-release-create) _message '[--tag v1.0.0] [--name "Release name"]' ;;
        (gitea-snippet-create) _message 'content: text for snippet' ;;
        (gitea-ci-runs)   _message '[--limit N]' ;;
        (gitea-ci-watch)  _message 'run_id: CI run ID to watch' ;;
        # Process watch
        (process-watch)   _message 'command: shell command to supervise' ;;
        (process-watch-list) # no args
            ;;
        # Cost tracker
        (cost-record)     _message 'action_name: agentd action  in: input tokens  out: output tokens' ;;
        (cost-stats)      # no args
            ;;
        # Cross-session history
        (history-index)   # no args
            ;;
        (history-search)  _message 'query: search all past session history' ;;
      esac ;;
  esac
}

_turtle_agentctl_cmds() {
  local -a cmds
  cmds=(
    # Agent planner
    'plan:Create a multi-step shell plan for a goal'
    'plan-execute:Create a multi-step shell plan (alias for plan)'
    'plan-next:Advance plan to the next step'
    'plan-status:Show current plan goal, steps, and progress'
    'plan-abort:Abort the current plan and clear terminal prompt queue'
    # AI intelligence
    'explain-selection:Explain terminal output or selected text using AI'
    'explain:Explain terminal text (alias for explain-selection)'
    'nl-to-shell:Convert a natural-language request to a shell command'
    'nl:Convert natural language to shell command (alias)'
    # Project context
    'atlas-context:Read the .atlas/ knowledge base from the current project'
    'atlas-acp-register:Register TurtleTerm with a local Atlas ACP instance'
    # Sessions & history
    'sessions:List known terminal sessions from the event stream'
    'inspect:Show recent events for a terminal session'
    'summarize:Summarize completed commands and failures for a session'
    'receipts:List command receipt files for a session'
    # Policy & security
    'policy-status:Check Policy Fabric reachability and evaluation mode'
    'policy-evaluate-local:Evaluate a command against local policy rules'
    # Integrations
    'noetica-status:Check whether the Noetica cognition loop is reachable'
    'noetica-query:Send a query to Noetica /api/chat'
    'agent-machine-probe:Probe the Agent Machine runtime for reachability'
    'bearbrowser-handoff:Delegate a browser task to BearBrowser via A2A protocol'
    # Infrastructure
    'ping:Check agentd health and version'
    'surfaces:List available execution surfaces (host, tmux, neovim, etc.)'
    # Bookmarks & history
    'bookmark-add:Save a command to bookmarks'
    'bookmark-list:List saved command bookmarks'
    'bookmark-remove:Remove a bookmark by command text'
    'semantic-history:AI-ranked history search'
    # Security & pre-exec
    'detect-secrets:Scan recent output for secrets/credentials'
    'pre-exec-risk:Risk-check a command before running'
    'shellcheck-lint:Lint a shell command with shellcheck'
    'inline-diff:Show inline diff for a proposed file change'
    'env-inspect:Inspect current environment variables'
    # Docker
    'docker-list:List running Docker containers'
    'docker-exec:Exec into a Docker container'
    'docker-logs:Stream logs from a Docker container'
    # SSH
    'ssh-profiles:List SSH config profiles'
    'ssh-connect:Connect to an SSH profile'
    # Events & commands
    'events-since:Show events since a timestamp or sequence'
    'wait-for-command:Block until a command completes in another pane'
    # Runbooks
    'runbook-list:List runbooks from .turtle/runbooks/'
    'runbook-run:Run a named runbook as a plan'
    'runbook-show:Show runbook steps without running'
    # Aliases
    'alias-learn:Learn a shell alias and its expansion'
    'alias-list:List learned aliases'
    'alias-apply:Apply a learned alias to a command'
    # Git & sessions
    'git-context:Show git repo context for current directory'
    'session-narrate:AI narrative summary of a terminal session'
    'share-session:Share a session read-only via URL'
    'stop-share:Stop sharing the current session'
    # Sync & voice
    'sync-push:Push config to remote sync URL'
    'sync-pull:Pull config from remote sync URL'
    'voice-to-shell:Transcribe voice input to shell command'
    # Coach & paste
    'coach-analyze:AI Terminal Coach analysis of recent commands'
    'smart-paste-sanitize:Sanitize clipboard text before pasting'
    # Security scanning
    'dep-vuln-scan:Scan dependencies for known vulnerabilities'
    'session-to-pr:Export a session as a GitHub PR description'
    # Memory
    'memory-add:Add a note to agent memory'
    'memory-list:List agent memory notes'
    'memory-forget:Remove a note from agent memory'
    'memory-search:Search agent memory notes'
    # Persona
    'persona-set:Set active AI persona'
    'persona-get:Show active AI persona'
    'persona-marketplace-list:List available personas from marketplace'
    'persona-marketplace-install:Install a persona from marketplace'
    # Workflows
    'workflow-detect:Detect workflow patterns from session history'
    'workflow-save:Save a detected workflow as a runbook'
    # Files & perf
    'file-tree:Browse files inline in the terminal'
    'perf-stats:View command performance statistics'
    'perf-record:Start recording command performance'
    # Output
    'output-export:Export output block (markdown/JSON/HTML/Gist)'
    'output-search:Fuzzy search through output history'
    # Plugins
    'plugin-list:List installed TurtleTerm plugins'
    'plugin-install:Install a TurtleTerm plugin'
    # Team
    'team-config-set:Set a team configuration value'
    'team-sync-pull:Pull team config from remote'
    'team-runbook-list:List team-shared runbooks'
    # SFTP
    'sftp-browse:Browse remote files via SFTP'
    'sftp-download:Download a file via SFTP'
    # Surface 2 — bg agent, webhooks, scratchpad, policy, hooks
    'bg-plan-start:Start an AI agent plan in the background'
    'bg-plan-list:List all background plans'
    'bg-plan-status:Get status of a background plan'
    'bg-plan-cancel:Cancel a running background plan'
    'webhook-add:Register a webhook URL to receive terminal events'
    'webhook-list:List registered webhooks'
    'webhook-remove:Remove a webhook by URL'
    'webhook-dispatch:Manually dispatch an event to all matching webhooks'
    'error-patterns:Detect repeated failing command patterns'
    'scratchpad-write:Write a note to the AI scratchpad'
    'scratchpad-read:Read a scratchpad note'
    'scratchpad-list:List all scratchpad notes'
    'policy-check:Check a command against .turtle/policy.yaml rules'
    'install-hooks:Install TurtleTerm pre-commit hooks in a git repo'
    'uninstall-hooks:Remove TurtleTerm pre-commit hooks'
    'dashboard:Get a structured dashboard snapshot'
    # Forge / Gitea
    'gitea-status:Check Gitea sovereign forge connection and version'
    'gitea-repo-list:List Gitea repositories'
    'gitea-pr-create:Create a PR on Gitea'
    'gitea-pr-list:List PRs on Gitea'
    'gitea-issue-create:Create an issue on Gitea'
    'gitea-release-create:Create a release/tag on Gitea'
    'gitea-snippet-create:Create a Gitea snippet (like gist)'
    'gitea-ci-runs:List recent Gitea Actions CI runs'
    'gitea-ci-watch:Watch a Gitea CI run until completion'
    # Process watch
    'process-watch:Start a supervised process that restarts on crash'
    'process-watch-list:List all supervised processes and their status'
    # Cost tracker
    'cost-record:Record an AI API call cost entry'
    'cost-stats:Show AI API cost breakdown by action and model'
    # Cross-session history
    'history-index:Index all past session command history for semantic search'
    'history-search:Search all past terminal session history'
  )
  _describe 'turtle-agentctl command' cmds
}

_turtle_agentctl "$@"
