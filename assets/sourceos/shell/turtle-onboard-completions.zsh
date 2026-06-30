#compdef turtle-onboard
# turtle-onboard zsh completion

_turtle_onboard() {
  _arguments \
    '--quick[Fast path: backend + shell + done]' \
    '--check[Run only the health-check step]' \
    '--no-input[Print everything, change nothing (CI / non-TTY safe)]' \
    '(-h --help)'{-h,--help}'[Show help]'
}

_turtle_onboard "$@"
