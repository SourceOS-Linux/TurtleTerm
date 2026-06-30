#compdef turtle-drive
# turtle-drive zsh completion

_turtle_drive() {
  local -a subcmds
  subcmds=(
    'list:Browse all workflows (chains, runbooks, bookmarks, drive)'
    'browse:Alias for list'
    'show:Print a workflow definition'
    'run:Execute a workflow (prompts for missing {{params}})'
    'save:Save a workflow into the drive'
    'export:Emit a portable file (md|json)'
    'export-all:Dump the whole drive'
    'import:Add a workflow from a portable file'
    'sync:Push/pull the drive to your Gitea forge'
  )

  local state
  _arguments '1: :->cmd' '*: :->args' && return 0

  _drive_names() {
    local -a names
    names=(${(f)"$(turtle-drive list --json 2>/dev/null | sed -n 's/.*\"name\": \"\([^\"]*\)\".*/\1/p')"})
    _describe 'workflow' names
  }

  case $state in
    cmd)
      _describe 'turtle-drive command' subcmds ;;
    args)
      case $words[2] in
        run|show|export) _drive_names ;;
        sync) _values 'direction' 'push' 'pull' ;;
        list|browse) _values 'option' '--tag' '--type' '--json' ;;
        save) _values 'option' '--type' '--cmd' '--body' '--from-chain' '--desc' '--tags' '--param' ;;
        export) _values 'option' '--format' ;;
      esac ;;
  esac
}

_turtle_drive "$@"
