#compdef turtle-share
# turtle-share zsh completion

_turtle_share() {
  local -a subcmds
  subcmds=(
    'start:Start (or reuse) a shared session'
    'join:Attach this terminal to a shared session'
    'list:List active shared sessions'
    'stop:Stop sharing and clean up the socket'
  )

  local state
  _arguments '1: :->cmd' '*: :->args' && return 0

  case $state in
    cmd)
      _describe 'turtle-share command' subcmds ;;
    args)
      case $words[2] in
        start)
          _arguments \
            '--name[shared session name]:name:' \
            '--mode[sharing mode]:mode:(local ssh tls)' \
            '--addr[TLS listener host:port]:addr:' \
            '--json[machine-readable output]' ;;
        join)
          # Offer known shared-session names.
          local statedir="${TURTLE_SHARE_STATE:-$HOME/.local/state/turtleterm/share}"
          local -a names
          names=(${statedir}/*.lua(N:t:r))
          _describe 'shared session' names ;;
        list)
          _values 'option' '--json' ;;
        stop)
          local statedir="${TURTLE_SHARE_STATE:-$HOME/.local/state/turtleterm/share}"
          local -a names
          names=(${statedir}/*.lua(N:t:r))
          _describe 'shared session' names ;;
      esac ;;
  esac
}

_turtle_share "$@"
