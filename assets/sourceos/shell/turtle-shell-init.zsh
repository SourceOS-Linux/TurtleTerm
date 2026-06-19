# TurtleTerm shell integration for zsh.
#
# Source from ~/.zshrc:
#   source /path/to/turtle-shell-init.zsh

[[ -n "${_TURTLE_SHELL_INIT_ZSH:-}" ]] && return 0
_TURTLE_SHELL_INIT_ZSH=1

if [[ -z "${SOURCEOS_TERMINAL_SESSION_ID:-}" ]]; then
    export SOURCEOS_TERMINAL_SESSION_ID="term-$(python3 -c 'import uuid; print(uuid.uuid4().hex)' 2>/dev/null || date +%s)"
fi

export SOURCEOS_TERMINAL_FRONTEND="${SOURCEOS_TERMINAL_FRONTEND:-turtle-term}"
export SOURCEOS_WORKSPACE="${SOURCEOS_WORKSPACE:-default}"

_turtle_writer() {
    local writer
    writer="${0:A:h}/../bin/turtle-agentd"
    [[ -x "$writer" ]] || writer="turtle-agentd"
    echo "$writer"
}

_TURTLE_ZSH_CMD=""
_TURTLE_ZSH_STARTED_AT=""

preexec() {
    local cmd="$1"
    [[ -z "$cmd" ]] && return
    _TURTLE_ZSH_CMD="$cmd"
    _TURTLE_ZSH_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"

    local writer
    writer="$(_turtle_writer)"
    local event_id="evt_$(python3 -c 'import uuid; print(uuid.uuid4().hex)' 2>/dev/null || echo "0")"
    _TURTLE_ZSH_EVT_ID="$event_id"

    python3 "$writer" --stdio 2>/dev/null <<EOF || true
{
  "action": "ingest_event",
  "event": {
    "event_id": "$event_id",
    "event_type": "command.started",
    "session_id": "${SOURCEOS_TERMINAL_SESSION_ID}",
    "workspace_id": "${SOURCEOS_WORKSPACE}",
    "actor_id": "human:local-user",
    "frontend": "${SOURCEOS_TERMINAL_FRONTEND}",
    "cwd": "$(pwd)",
    "command": $(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$cmd" 2>/dev/null || echo '"'"$cmd"'"'),
    "started_at": "$_TURTLE_ZSH_STARTED_AT",
    "shell": "zsh"
  }
}
EOF
}

precmd() {
    local exit_status=$?
    local completed_at
    completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"

    [[ -z "$_TURTLE_ZSH_CMD" ]] && return

    local cmd="$_TURTLE_ZSH_CMD"
    local started_at="$_TURTLE_ZSH_STARTED_AT"
    local event_id="${_TURTLE_ZSH_EVT_ID:-evt_0}"

    _TURTLE_ZSH_CMD=""
    _TURTLE_ZSH_EVT_ID=""

    local writer
    writer="$(_turtle_writer)"

    python3 "$writer" --stdio 2>/dev/null <<EOF || true
{
  "action": "ingest_event",
  "event": {
    "event_id": "${event_id}_completed",
    "event_type": "command.completed",
    "session_id": "${SOURCEOS_TERMINAL_SESSION_ID}",
    "workspace_id": "${SOURCEOS_WORKSPACE}",
    "actor_id": "human:local-user",
    "frontend": "${SOURCEOS_TERMINAL_FRONTEND}",
    "cwd": "$(pwd)",
    "command": $(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$cmd" 2>/dev/null || echo '"'"$cmd"'"'),
    "exit_status": $exit_status,
    "started_at": "$started_at",
    "completed_at": "$completed_at",
    "shell": "zsh"
  }
}
EOF
}
