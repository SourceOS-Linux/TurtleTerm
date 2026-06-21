# turtle-gh bash completion
_turtle_gh_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  local sub="${COMP_WORDS[1]}"

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=($(compgen -W "repo pr issue release gist run workflow secret label search status auth api" -- "$cur"))
  elif [[ $COMP_CWORD -eq 2 ]]; then
    case $sub in
      repo)     COMPREPLY=($(compgen -W "create fork view clone" -- "$cur")) ;;
      pr)       COMPREPLY=($(compgen -W "create list view checkout merge close comment diff" -- "$cur")) ;;
      issue)    COMPREPLY=($(compgen -W "create list view close comment" -- "$cur")) ;;
      release)  COMPREPLY=($(compgen -W "create list" -- "$cur")) ;;
      run)      COMPREPLY=($(compgen -W "list watch cancel" -- "$cur")) ;;
      workflow) COMPREPLY=($(compgen -W "list run enable disable" -- "$cur")) ;;
      search)   COMPREPLY=($(compgen -W "repos issues prs code" -- "$cur")) ;;
      auth)     COMPREPLY=($(compgen -W "status token" -- "$cur")) ;;
      label)    COMPREPLY=($(compgen -W "list create edit delete" -- "$cur")) ;;
      secret)   COMPREPLY=($(compgen -W "list set delete" -- "$cur")) ;;
    esac
  fi
}
complete -F _turtle_gh_completions turtle-gh
