# turtle-onboard bash completion
_turtle_onboard_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=($(compgen -W "--quick --check --no-input --help -h" -- "$cur"))
}
complete -F _turtle_onboard_completions turtle-onboard
