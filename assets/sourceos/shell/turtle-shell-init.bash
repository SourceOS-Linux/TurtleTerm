# TurtleTerm shell integration for bash.
#
# Source this from ~/.bashrc or ~/.bash_profile:
#   source /path/to/turtle-shell-init.bash
#
# Or let the TurtleTerm profile auto-source it via $TURTLE_SHELL_INIT.

# Guard against double-sourcing.
[[ -n "${_TURTLE_SHELL_INIT_BASH:-}" ]] && return 0
_TURTLE_SHELL_INIT_BASH=1

# Ensure a stable session ID for this shell instance.
if [[ -z "${SOURCEOS_TERMINAL_SESSION_ID:-}" ]]; then
    export SOURCEOS_TERMINAL_SESSION_ID="term-$(python3 -c 'import uuid; print(uuid.uuid4().hex)' 2>/dev/null || date +%s%N)"
fi

export SOURCEOS_TERMINAL_FRONTEND="${SOURCEOS_TERMINAL_FRONTEND:-turtle-term}"
export SOURCEOS_WORKSPACE="${SOURCEOS_WORKSPACE:-default}"

# Path to the event writer; resolved relative to this file or from PATH.
_turtle_writer() {
    local writer
    writer="$(dirname "${BASH_SOURCE[0]}")/../bin/turtle-agentd"
    if [[ ! -x "$writer" ]]; then
        writer="turtle-agentd"
    fi
    echo "$writer"
}

_TURTLE_CMD_START_TIME=""
_TURTLE_CMD_PENDING=""
_TURTLE_CMD_STARTED_AT=""

# Fired before each command via the DEBUG trap.
_turtle_preexec() {
    local cmd="$BASH_COMMAND"
    # Skip empty commands, prompts, and internal turtle commands.
    [[ -z "$cmd" ]] && return
    [[ "$cmd" == _turtle_* ]] && return
    [[ "$cmd" == "__turtle"* ]] && return

    _TURTLE_CMD_PENDING="$cmd"
    _TURTLE_CMD_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"

    local event_id="evt_$(python3 -c 'import uuid; print(uuid.uuid4().hex)' 2>/dev/null || echo "$(date +%s%N)")"
    local writer
    writer="$(_turtle_writer)"

    python3 "$writer" --stdio <<EOF 2>/dev/null || true
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
    "command": $(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$cmd" 2>/dev/null || echo '"'$cmd'"'),
    "started_at": "$_TURTLE_CMD_STARTED_AT",
    "shell": "bash"
  }
}
EOF
    # Store the event_id for the completion hook.
    _TURTLE_CMD_PENDING_EVT="$event_id"
}

# Fired before each prompt (after command completes) via PROMPT_COMMAND.
_turtle_precmd() {
    local exit_status=$?
    local completed_at
    completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"

    [[ -z "$_TURTLE_CMD_PENDING" ]] && return

    local cmd="$_TURTLE_CMD_PENDING"
    local started_at="${_TURTLE_CMD_STARTED_AT}"
    local event_id="${_TURTLE_CMD_PENDING_EVT:-evt_$(python3 -c 'import uuid; print(uuid.uuid4().hex)' 2>/dev/null || echo "0")}"

    _TURTLE_CMD_PENDING=""
    _TURTLE_CMD_PENDING_EVT=""

    local writer
    writer="$(_turtle_writer)"

    python3 "$writer" --stdio <<EOF 2>/dev/null || true
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
    "command": $(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$cmd" 2>/dev/null || echo '"'$cmd'"'),
    "exit_status": $exit_status,
    "started_at": "$started_at",
    "completed_at": "$completed_at",
    "shell": "bash"
  }
}
EOF
    return $exit_status
}

# Install hooks.
trap '_turtle_preexec' DEBUG
if [[ -n "${PROMPT_COMMAND:-}" ]]; then
    PROMPT_COMMAND="_turtle_precmd; $PROMPT_COMMAND"
else
    PROMPT_COMMAND="_turtle_precmd"
fi
