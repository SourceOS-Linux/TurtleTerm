# TurtleTerm agent controller — bash completions.
# Add to ~/.bashrc: source /path/to/turtle-agentctl-completions.bash
# Or install in /etc/bash_completion.d/

_turtle_agentctl_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmds="plan plan-execute plan-next plan-status plan-abort explain-selection explain nl-to-shell nl atlas-context atlas-acp-register sessions inspect summarize receipts policy-status policy-evaluate-local noetica-status noetica-query agent-machine-probe bearbrowser-handoff ping surfaces bookmark-add bookmark-list bookmark-remove semantic-history detect-secrets pre-exec-risk shellcheck-lint inline-diff env-inspect docker-list docker-exec docker-logs ssh-profiles ssh-connect events-since wait-for-command runbook-list runbook-run runbook-show alias-learn alias-list alias-apply git-context session-narrate share-session stop-share sync-push sync-pull voice-to-shell coach-analyze smart-paste-sanitize dep-vuln-scan session-to-pr memory-add memory-list memory-forget memory-search persona-set persona-get persona-marketplace-list persona-marketplace-install workflow-detect workflow-save file-tree perf-stats perf-record output-export output-search plugin-list plugin-install team-config-set team-sync-pull team-runbook-list sftp-browse sftp-download"
    if [[ "${COMP_CWORD}" -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${cmds}" -- "${cur}") )
    fi
}

complete -F _turtle_agentctl_completions turtle-agentctl
