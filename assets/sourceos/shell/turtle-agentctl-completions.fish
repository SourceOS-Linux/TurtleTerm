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

# Argument hints for subcommands
complete -c turtle-agentctl -n '__fish_seen_subcommand_from plan plan-execute' -a "(echo 'goal...')" -d 'Goal description'
complete -c turtle-agentctl -n '__fish_seen_subcommand_from runbook-run runbook-show' -a "(turtle-agentctl --stdio runbook-list 2>/dev/null | python3 -c \"import json,sys; [print(r['name']) for r in json.load(sys.stdin).get('data',{}).get('runbooks',[])]\" 2>/dev/null)" -d 'Runbook name'
complete -c turtle-agentctl -n '__fish_seen_subcommand_from atlas-context' -a "(__fish_complete_directories)" -d 'Project directory'
