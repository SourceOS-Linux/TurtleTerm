# TurtleTerm shell integration for bash.
#
# Source from ~/.bashrc or ~/.bash_profile:
#   source /path/to/turtle-shell-init.bash

[[ -n "${_TURTLE_SHELL_INIT_BASH:-}" ]] && return 0
_TURTLE_SHELL_INIT_BASH=1

if [[ -z "${SOURCEOS_TERMINAL_SESSION_ID:-}" ]]; then
    export SOURCEOS_TERMINAL_SESSION_ID="term-$(python3 -c 'import uuid; print(uuid.uuid4().hex)' 2>/dev/null || date +%s)"
fi

export SOURCEOS_TERMINAL_FRONTEND="${SOURCEOS_TERMINAL_FRONTEND:-turtle-term}"
export SOURCEOS_WORKSPACE="${SOURCEOS_WORKSPACE:-default}"

_turtle_writer() {
    local writer
    writer="$(dirname "${BASH_SOURCE[0]}")/../bin/turtle-agentd"
    [[ -x "$writer" ]] || writer="turtle-agentd"
    echo "$writer"
}

_turtle_state_dir() {
    echo "${XDG_STATE_HOME:-$HOME/.local/state}/sourceos/terminal"
}

_turtle_check_dangerous() {
    local cmd="$1"
    local patterns=(
        'rm[[:space:]]+-rf[[:space:]]+'
        'git[[:space:]]+push[[:space:]]+.*--force'
        'git[[:space:]]+push[[:space:]]+-f'
        'DROP[[:space:]]+TABLE'
        '\|[[:space:]]*sh'
        'sudo[[:space:]]+rm[[:space:]]+-rf'
        'kill[[:space:]]+-9[[:space:]]+1'
    )
    for pattern in "${patterns[@]}"; do
        if [[ "$cmd" =~ $pattern ]]; then
            printf '\e[33m⚠  TurtleTerm policy: dangerous pattern detected — review before running\e[0m\n' >&2
            local writer; writer="$(_turtle_writer)"
            python3 "$writer" --stdio >/dev/null 2>&1 <<EOF &
{"action": "ingest_event", "event": {"event_type": "policy.dangerous_pattern", "session_id": "${SOURCEOS_TERMINAL_SESSION_ID}", "command": "dangerous command intercepted", "shell": "bash"}}
EOF
            return
        fi
    done
}

_TURTLE_CMD_START_EPOCH=0
_TURTLE_CMD_PENDING=""
_TURTLE_CMD_STARTED_AT=""
_TURTLE_CMD_PENDING_EVT=""

_turtle_preexec() {
    local cmd="$BASH_COMMAND"
    [[ -z "$cmd" ]] && return
    [[ "$cmd" == _turtle_* ]] && return
    [[ "$cmd" == "__turtle"* ]] && return

    _TURTLE_CMD_PENDING="$cmd"
    _TURTLE_CMD_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"
    _TURTLE_CMD_START_EPOCH=$(date +%s 2>/dev/null || echo 0)

    # OSC 133 C — command output start
    printf '\e]133;C\a'

    _turtle_check_dangerous "$cmd"

    local event_id="evt_$(python3 -c 'import uuid; print(uuid.uuid4().hex)' 2>/dev/null || echo "0")"
    _TURTLE_CMD_PENDING_EVT="$event_id"
    local writer; writer="$(_turtle_writer)"

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
}

_turtle_precmd() {
    local exit_status=$?
    local completed_at
    completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"

    # OSC 133 D + A — end command, start prompt
    printf '\e]133;D;%d\a' $exit_status
    printf '\e]133;A\a'

    # Write exit code + timing for status bar
    local state_dir; state_dir="$(_turtle_state_dir)"
    mkdir -p "$state_dir" 2>/dev/null || true
    printf '%d' $exit_status > "$state_dir/last_exit" 2>/dev/null || true
    if [[ ${_TURTLE_CMD_START_EPOCH:-0} -gt 0 ]]; then
        local _now; _now=$(date +%s 2>/dev/null || echo 0)
        local _elapsed=$(( _now - _TURTLE_CMD_START_EPOCH ))
        printf '%d' "$_elapsed" > "$state_dir/last_duration" 2>/dev/null || true
    fi

    # Long command notification
    if [[ -n "$_TURTLE_CMD_PENDING" && $_TURTLE_CMD_START_EPOCH -gt 0 ]]; then
        local now; now=$(date +%s 2>/dev/null || echo 0)
        local elapsed=$(( now - _TURTLE_CMD_START_EPOCH ))
        local threshold="${TURTLE_NOTIFY_THRESHOLD:-10}"
        if [[ "$threshold" != "0" && $elapsed -ge $threshold ]]; then
            local short_cmd="${_TURTLE_CMD_PENDING:0:50}"
            osascript -e "display notification \"${short_cmd} (${elapsed}s, exit ${exit_status})\" with title \"TurtleTerm\"" 2>/dev/null &
        fi
    fi

    [[ -z "$_TURTLE_CMD_PENDING" ]] && return $exit_status

    local cmd="$_TURTLE_CMD_PENDING"
    local started_at="${_TURTLE_CMD_STARTED_AT}"
    local event_id="${_TURTLE_CMD_PENDING_EVT:-evt_0}"

    _TURTLE_CMD_PENDING=""
    _TURTLE_CMD_PENDING_EVT=""
    _TURTLE_CMD_START_EPOCH=0

    local writer; writer="$(_turtle_writer)"

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

trap '_turtle_preexec' DEBUG
if [[ -n "${PROMPT_COMMAND:-}" ]]; then
    PROMPT_COMMAND="_turtle_precmd; $PROMPT_COMMAND"
else
    PROMPT_COMMAND="_turtle_precmd"
fi
