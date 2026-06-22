#compdef turtle-copilot
# turtle-copilot zsh completion

_turtle_copilot() {
  local -a subcmds
  subcmds=(
    'start:Start the co-pilot watcher'
    'stop:Stop the watcher'
    'status:Show status and recent suggestions'
    'chat:Multi-turn conversation'
    'suggest:View latest proactive suggestions'
    'recall:Recall past fixes (fast local lookup)'
    'context:Show gathered co-pilot context'
    'remember:Store a manual fix'
    'memory:List stored fix memories'
    'backends:List available AI backends'
    'use:Switch backend (claude|ollama|noetica)'
    'config:View or update configuration'
  )

  local state
  _arguments '1: :->cmd' '*: :->args' && return 0

  case $state in
    cmd)
      _describe 'turtle-copilot command' subcmds ;;
    args)
      case $words[2] in
        use)
          local -a backends
          backends=('claude:Claude API (ANTHROPIC_API_KEY)' 'ollama:Local Ollama LLM' 'noetica:Self-hosted Noetica')
          _describe 'backend' backends ;;
        config)
          local -a keys
          keys=('backend=' 'model=' 'endpoint=' 'auto_explain_errors=' 'auto_suggest_slow=' 'slow_threshold_ms=')
          _describe 'config key' keys ;;
        memory)
          _values 'option' '--limit' '--json' ;;
        context)
          _values 'option' '--json' ;;
      esac ;;
  esac
}

_turtle_copilot "$@"
