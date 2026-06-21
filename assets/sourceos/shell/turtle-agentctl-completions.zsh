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
        nl-to-shell|nl)  _message 'request: natural language description of shell command' ;;
        atlas-context)  _files -/ ;;
        inspect|summarize|receipts)  _message 'session_id: terminal session ID (optional)' ;;
        noetica-query)  _message 'text: query to send to Noetica' ;;
        policy-evaluate-local)  _message 'command: shell command to evaluate against policy rules' ;;
        bearbrowser-handoff)  _message 'task: browser task description to delegate to BearBrowser' ;;
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
  )
  _describe 'turtle-agentctl command' cmds
}

_turtle_agentctl "$@"
