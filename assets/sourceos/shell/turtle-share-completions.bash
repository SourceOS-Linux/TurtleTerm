# turtle-share bash completion
_turtle_share_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local sub="${COMP_WORDS[1]}"
  local statedir="${TURTLE_SHARE_STATE:-$HOME/.local/state/turtleterm/share}"

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=($(compgen -W "start join list stop" -- "$cur"))
    return
  fi

  case $sub in
    start)
      if [[ "$cur" == --* ]]; then
        COMPREPLY=($(compgen -W "--name --mode --addr --json" -- "$cur"))
      elif [[ "${COMP_WORDS[COMP_CWORD-1]}" == "--mode" ]]; then
        COMPREPLY=($(compgen -W "local ssh tls" -- "$cur"))
      fi ;;
    join|stop)
      local names
      names=$(ls "$statedir"/*.lua 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.lua$//')
      COMPREPLY=($(compgen -W "$names" -- "$cur")) ;;
    list)
      COMPREPLY=($(compgen -W "--json" -- "$cur")) ;;
  esac
}
complete -F _turtle_share_completions turtle-share
