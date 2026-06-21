# TurtleTerm agent controller — bash completions.
# Add to ~/.bashrc: source /path/to/turtle-agentctl-completions.bash
# Or install in /etc/bash_completion.d/

_turtle_agentctl_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmds="plan plan-execute plan-next plan-status plan-abort explain-selection explain nl-to-shell nl atlas-context atlas-acp-register sessions inspect summarize receipts policy-status policy-evaluate-local noetica-status noetica-query agent-machine-probe bearbrowser-handoff ping surfaces"
    if [[ "${COMP_CWORD}" -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${cmds}" -- "${cur}") )
    fi
}

complete -F _turtle_agentctl_completions turtle-agentctl
