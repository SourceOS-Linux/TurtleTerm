# turtle-copilot bash completion
_turtle_copilot_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local sub="${COMP_WORDS[1]}"

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=($(compgen -W "start stop status chat suggest backends use config" -- "$cur"))
  elif [[ $COMP_CWORD -eq 2 ]]; then
    case $sub in
      use) COMPREPLY=($(compgen -W "claude ollama noetica" -- "$cur")) ;;
    esac
  fi
}
complete -F _turtle_copilot_completions turtle-copilot
