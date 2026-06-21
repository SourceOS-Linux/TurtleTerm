# TurtleTerm agent controller — fish completions.
# Install: copy to ~/.config/fish/completions/ or source from config.fish.

# Disable file completions for turtle-agentctl
complete -c turtle-agentctl -f

# Global flags
complete -c turtle-agentctl -l stdio   -d 'Read one JSON request from stdin, write one JSON response'
complete -c turtle-agentctl -l http    -d 'Start HTTP daemon on PORT (default 7722)' -r
complete -c turtle-agentctl -l socket  -d 'Unix socket path for daemon mode' -r
complete -c turtle-agentctl -l help    -d 'Show help message'

# Subcommands
function __turtle_no_subcommand
    not __fish_seen_subcommand_from \
        plan plan-execute plan-next plan-status plan-abort \
        explain-selection explain nl-to-shell nl \
        atlas-context atlas-acp-register \
        sessions inspect summarize receipts \
        policy-status policy-evaluate-local \
        noetica-status noetica-query \
        agent-machine-probe bearbrowser-handoff \
        semantic-history bookmark-add bookmark-list bookmark-remove \
        runbook-list runbook-run runbook-show \
        detect-secrets pre-exec-risk shellcheck-lint inline-diff env-inspect \
        docker-list docker-exec docker-logs \
        ssh-profiles ssh-connect \
        events-since wait-for-command \
        alias-learn alias-list alias-apply \
        git-context session-narrate share-session stop-share \
        sync-push sync-pull voice-to-shell \
        coach-analyze smart-paste-sanitize dep-vuln-scan session-to-pr \
        memory-add memory-list memory-forget memory-search \
        persona-set persona-get persona-marketplace-list persona-marketplace-install \
        workflow-detect workflow-save \
        file-tree perf-stats perf-record \
        output-export output-search \
        plugin-list plugin-install \
        team-config-set team-sync-pull team-runbook-list \
        sftp-browse sftp-download \
        ping surfaces
end

# Agent planner
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a plan             -d 'Create a multi-step shell plan for a goal'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a plan-execute     -d 'Create a multi-step shell plan (alias for plan)'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a plan-next        -d 'Advance plan to next step'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a plan-status      -d 'Show current plan goal and progress'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a plan-abort       -d 'Abort the current plan'

# AI intelligence
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a explain-selection -d 'Explain terminal output or selected text (AI)'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a explain           -d 'Explain terminal text (alias)'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a nl-to-shell       -d 'Convert natural-language to shell command'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a nl                -d 'Natural language → shell (alias)'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a semantic-history  -d 'AI-ranked history search'

# Bookmarks
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a bookmark-add     -d 'Save a command to bookmarks'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a bookmark-list    -d 'List saved command bookmarks'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a bookmark-remove  -d 'Remove a bookmark by command text'

# Runbooks
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a runbook-list     -d 'List runbooks from .turtle/runbooks/'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a runbook-run      -d 'Run a named runbook as a plan'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a runbook-show     -d 'Show runbook steps without running'

# Project context
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a atlas-context    -d 'Read .atlas/ knowledge base from project'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a atlas-acp-register -d 'Register TurtleTerm with Atlas ACP'

# Sessions & history
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a sessions         -d 'List known terminal sessions'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a inspect          -d 'Show recent events for a session'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a summarize        -d 'Summarize session commands and failures'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a receipts         -d 'List command receipt files for a session'

# Policy & security
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a policy-status          -d 'Check Policy Fabric reachability'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a policy-evaluate-local  -d 'Evaluate a command against local policy'

# Integrations
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a noetica-status    -d 'Check Noetica cognition loop reachability'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a noetica-query     -d 'Send a query to Noetica /api/chat'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a agent-machine-probe -d 'Probe Agent Machine runtime'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a bearbrowser-handoff -d 'Delegate task to BearBrowser via A2A'

# Infrastructure
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a ping    -d 'Check agentd health and version'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a surfaces -d 'List execution surfaces'

# Security & pre-exec
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a detect-secrets       -d 'Scan recent output for secrets/credentials'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a pre-exec-risk        -d 'Risk-check a command before running'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a shellcheck-lint      -d 'Lint a shell command with shellcheck'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a inline-diff          -d 'Show inline diff for a proposed file change'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a env-inspect          -d 'Inspect current environment variables'

# Docker
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a docker-list          -d 'List running Docker containers'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a docker-exec          -d 'Exec into a Docker container'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a docker-logs          -d 'Stream logs from a Docker container'

# SSH
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a ssh-profiles         -d 'List SSH config profiles'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a ssh-connect          -d 'Connect to an SSH profile'

# Events & commands
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a events-since         -d 'Show events since a timestamp or sequence'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a wait-for-command     -d 'Block until a command completes in another pane'

# Aliases
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a alias-learn          -d 'Learn a shell alias and its expansion'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a alias-list           -d 'List learned aliases'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a alias-apply          -d 'Apply a learned alias to a command'

# Git & sessions
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a git-context          -d 'Show git repo context for current directory'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a session-narrate      -d 'AI narrative summary of a terminal session'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a share-session        -d 'Share a session read-only via URL'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a stop-share           -d 'Stop sharing the current session'

# Sync & voice
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a sync-push            -d 'Push config to remote sync URL'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a sync-pull            -d 'Pull config from remote sync URL'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a voice-to-shell       -d 'Transcribe voice input to shell command'

# Coach & paste
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a coach-analyze        -d 'AI Terminal Coach analysis of recent commands'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a smart-paste-sanitize -d 'Sanitize clipboard text before pasting'

# Security scanning
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a dep-vuln-scan        -d 'Scan dependencies for known vulnerabilities'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a session-to-pr        -d 'Export a session as a GitHub PR description'

# Memory
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a memory-add           -d 'Add a note to agent memory'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a memory-list          -d 'List agent memory notes'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a memory-forget        -d 'Remove a note from agent memory'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a memory-search        -d 'Search agent memory notes'

# Persona
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a persona-set                  -d 'Set active AI persona'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a persona-get                  -d 'Show active AI persona'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a persona-marketplace-list     -d 'List available personas from marketplace'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a persona-marketplace-install  -d 'Install a persona from marketplace'

# Workflows
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a workflow-detect      -d 'Detect workflow patterns from session history'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a workflow-save        -d 'Save a detected workflow as a runbook'

# Files & perf
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a file-tree            -d 'Browse files inline in the terminal'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a perf-stats           -d 'View command performance statistics'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a perf-record          -d 'Start recording command performance'

# Output
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a output-export        -d 'Export output block (markdown/JSON/HTML/Gist)'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a output-search        -d 'Fuzzy search through output history'

# Plugins
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a plugin-list          -d 'List installed TurtleTerm plugins'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a plugin-install       -d 'Install a TurtleTerm plugin'

# Team
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a team-config-set      -d 'Set a team configuration value'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a team-sync-pull       -d 'Pull team config from remote'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a team-runbook-list    -d 'List team-shared runbooks'

# SFTP
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a sftp-browse          -d 'Browse remote files via SFTP'
complete -c turtle-agentctl -n '__turtle_no_subcommand' -a sftp-download        -d 'Download a file via SFTP'

# Argument hints for subcommands
complete -c turtle-agentctl -n '__fish_seen_subcommand_from plan plan-execute' -a "(echo 'goal...')" -d 'Goal description'
complete -c turtle-agentctl -n '__fish_seen_subcommand_from runbook-run runbook-show' -a "(turtle-agentctl --stdio runbook-list 2>/dev/null | python3 -c \"import json,sys; [print(r['name']) for r in json.load(sys.stdin).get('data',{}).get('runbooks',[])]\" 2>/dev/null)" -d 'Runbook name'
complete -c turtle-agentctl -n '__fish_seen_subcommand_from atlas-context' -a "(__fish_complete_directories)" -d 'Project directory'
