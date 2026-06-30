# turtle-drive bash completion
_turtle_drive_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local sub="${COMP_WORDS[1]}"

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=($(compgen -W "list browse show run save export export-all import sync" -- "$cur"))
    return
  fi

  case $sub in
    run|show|export)
      if [[ $COMP_CWORD -eq 2 ]]; then
        local names
        names=$(turtle-drive list --json 2>/dev/null | sed -n 's/.*"name": "\([^"]*\)".*/\1/p')
        COMPREPLY=($(compgen -W "$names" -- "$cur"))
      elif [[ "$sub" == "export" ]]; then
        COMPREPLY=($(compgen -W "--format" -- "$cur"))
      fi
      ;;
    sync)   COMPREPLY=($(compgen -W "push pull" -- "$cur")) ;;
    list|browse) COMPREPLY=($(compgen -W "--tag --type --json" -- "$cur")) ;;
    save)   COMPREPLY=($(compgen -W "--type --cmd --body --from-chain --desc --tags --param" -- "$cur")) ;;
  esac
}
complete -F _turtle_drive_completions turtle-drive
