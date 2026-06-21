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

_turtle_state_dir() {
    echo "${XDG_STATE_HOME:-$HOME/.local/state}/sourceos/terminal"
}

# Dangerous command patterns — warn but don't block
_TURTLE_DANGEROUS_PATTERNS=(
    'rm[[:space:]]+-rf[[:space:]]+/'
    'rm[[:space:]]+-rf[[:space:]]+~'
    'git[[:space:]]+push[[:space:]]+.*--force'
    'git[[:space:]]+push[[:space:]]+-f'
    'DROP[[:space:]]+TABLE'
    '\|[[:space:]]*sh'
    'sudo[[:space:]]+rm[[:space:]]+-rf'
    'kill[[:space:]]+-9[[:space:]]+1$'
    ':\(\)\{.*\}'
)

_turtle_check_dangerous() {
    local cmd="$1"
    local matched=0
    for pattern in "${_TURTLE_DANGEROUS_PATTERNS[@]}"; do
        if [[ "$cmd" =~ $pattern ]]; then
            matched=1
            break
        fi
    done
    if (( matched )); then
        printf '\e[33m⚠  TurtleTerm policy: dangerous pattern detected — review before running\e[0m\n' >&2
        local writer; writer="$(_turtle_writer)"
        python3 "$writer" --stdio >/dev/null 2>&1 <<EOF &
{"action": "ingest_event", "event": {"event_type": "policy.dangerous_pattern", "session_id": "${SOURCEOS_TERMINAL_SESSION_ID}", "command": "dangerous command intercepted", "shell": "zsh"}}
EOF
    fi
}

_TURTLE_ZSH_CMD=""
_TURTLE_ZSH_STARTED_AT=""
_TURTLE_ZSH_CMD_EPOCH=0
_TURTLE_ZSH_EVT_ID=""

preexec() {
    local cmd="$1"
    [[ -z "$cmd" ]] && return
    _TURTLE_ZSH_CMD="$cmd"
    _TURTLE_ZSH_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"
    _TURTLE_ZSH_CMD_EPOCH=${EPOCHSECONDS:-0}

    # OSC 133 C — command output start (marks command start for prompt jumping)
    printf '\e]133;C\a'

    # Dangerous pattern check
    _turtle_check_dangerous "$cmd"

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

    # OSC 133 D — command end with exit code
    printf '\e]133;D;%d\a' $exit_status
    # OSC 133 A — prompt start (enables cmd+up/down jumping in WezTerm)
    printf '\e]133;A\a'

    # Write exit code + timing for status bar
    local state_dir; state_dir="$(_turtle_state_dir)"
    mkdir -p "$state_dir" 2>/dev/null || true
    printf '%d' $exit_status > "$state_dir/last_exit" 2>/dev/null || true
    if [[ ${_TURTLE_ZSH_CMD_EPOCH:-0} -gt 0 ]]; then
        local _elapsed=$(( ${EPOCHSECONDS:-0} - _TURTLE_ZSH_CMD_EPOCH ))
        printf '%d' "$_elapsed" > "$state_dir/last_duration" 2>/dev/null || true
    fi

    # Long command notification (>10s, skipped if TURTLE_NOTIFY_THRESHOLD=0)
    if [[ -n "$_TURTLE_ZSH_CMD" && ${_TURTLE_ZSH_CMD_EPOCH:-0} -gt 0 ]]; then
        local elapsed=$(( ${EPOCHSECONDS:-0} - _TURTLE_ZSH_CMD_EPOCH ))
        local threshold="${TURTLE_NOTIFY_THRESHOLD:-10}"
        if [[ "$threshold" != "0" && $elapsed -ge $threshold ]]; then
            local short_cmd="${_TURTLE_ZSH_CMD:0:50}"
            osascript -e "display notification \"${short_cmd} (${elapsed}s, exit ${exit_status})\" with title \"TurtleTerm\"" 2>/dev/null &!
        fi
    fi

    [[ -z "$_TURTLE_ZSH_CMD" ]] && return

    local cmd="$_TURTLE_ZSH_CMD"
    local started_at="$_TURTLE_ZSH_STARTED_AT"
    local event_id="${_TURTLE_ZSH_EVT_ID:-evt_0}"
    local completed_at
    completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"

    _TURTLE_ZSH_CMD=""
    _TURTLE_ZSH_EVT_ID=""
    _TURTLE_ZSH_CMD_EPOCH=0

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

# ============================================================
# AI ghost-text — two modes:
#   1. Explicit: ALT+/ or CTRL+SPACE fires immediately (synchronous)
#   2. Debounced: auto-fires after ~1s of idle if ANTHROPIC_API_KEY set
#      Uses background process + TRAPALRM — never blocks the prompt
# ============================================================

_turtle_ai_complete() {
    # If a suggestion is pending and buffer matches what we fetched for, accept it
    if [[ -n "$_TURTLE_GHOST_SUGGESTION" && "$BUFFER" == "$_TURTLE_GHOST_BUF" ]]; then
        BUFFER="$_TURTLE_GHOST_SUGGESTION"
        CURSOR=${#BUFFER}
        _TURTLE_GHOST_SUGGESTION=""
        _TURTLE_GHOST_BUF=""
        zle reset-prompt
        return
    fi

    # Otherwise fetch synchronously and show as preview
    local current_buffer="$BUFFER"
    [[ -z "$current_buffer" ]] && return
    _TURTLE_GHOST_SUGGESTION=""

    local result
    result=$(turtle-agentctl nl-to-shell "$current_buffer" 2>/dev/null | \
             python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('command',''))" 2>/dev/null)

    if [[ -n "$result" && "$result" != "$current_buffer" ]]; then
        _TURTLE_GHOST_SUGGESTION="$result"
        _TURTLE_GHOST_BUF="$current_buffer"
        zle -M "  AI▸ $result  [ALT+/ to accept]"
    fi
}
zle -N _turtle_ai_complete
bindkey '\e/' _turtle_ai_complete   # ALT+/
bindkey '^@' _turtle_ai_complete    # CTRL+SPACE

# G9: AI alias learning — track corrections after AI suggestions
_turtle_alias_learn() {
    local original="$_TURTLE_GHOST_BUF"
    local correction="$BUFFER"
    if [[ -n "$original" && -n "$correction" && "$original" != "$correction" && ${#correction} -gt 3 ]]; then
        # Fire-and-forget: record the correction asynchronously
        (turtle-agentctl --stdio alias-learn "$original" "$correction" >/dev/null 2>&1 &)
    fi
    _TURTLE_GHOST_BUF=""
    _TURTLE_GHOST_SUGGESTION=""
}
# Hook into ACCEPT_LINE: when user accepts a line, check if it differs from the AI suggestion
_turtle_learn_hook() {
    _turtle_alias_learn
    zle .accept-line
}
zle -N accept-line _turtle_learn_hook 2>/dev/null || true

# ---- Debounced auto-ghost (only when ANTHROPIC_API_KEY is set) ----

if [[ -n "${ANTHROPIC_API_KEY:-}" || "${TURTLE_GHOST_TEXT:-}" == "1" ]]; then

_TURTLE_GHOST_BUF=""       # buffer seen last tick
_TURTLE_GHOST_STABLE=0     # 1 = buffer unchanged for one tick → ready to fetch
_TURTLE_GHOST_PID=0        # pid of background nl-to-shell process
_TURTLE_GHOST_FILE="/tmp/turtle-ghost-$$.txt"
_TURTLE_GHOST_SUGGESTION=""  # pending AI suggestion (shown but not yet accepted)

# Cleanup on shell exit
trap 'rm -f "$_TURTLE_GHOST_FILE"; [[ $_TURTLE_GHOST_PID -gt 0 ]] && kill "$_TURTLE_GHOST_PID" 2>/dev/null' EXIT

_turtle_ghost_tick() {
    local buf="$BUFFER"

    # --- Phase 1: consume a finished result ---
    if [[ $_TURTLE_GHOST_PID -gt 0 && -f "$_TURTLE_GHOST_FILE" ]]; then
        if ! kill -0 "$_TURTLE_GHOST_PID" 2>/dev/null; then
            local result; result="$(cat "$_TURTLE_GHOST_FILE" 2>/dev/null)"
            rm -f "$_TURTLE_GHOST_FILE"
            _TURTLE_GHOST_PID=0
            # Only inject if buffer hasn't changed since we kicked off the fetch
            if [[ -n "$result" && "$result" != "$buf" && "$buf" == "$_TURTLE_GHOST_BUF" ]]; then
                _TURTLE_GHOST_SUGGESTION="$result"
                zle -M "  AI▸ $result  [ALT+/ to accept]"
                _TURTLE_GHOST_STABLE=0
                return
            fi
        fi
    fi

    # --- Phase 2: maybe launch a new fetch ---
    # Don't launch if: buffer too short, fetch running, or buffer is empty
    [[ ${#buf} -lt 4 || $_TURTLE_GHOST_PID -gt 0 || -z "$buf" ]] && return

    if [[ "$buf" == "$_TURTLE_GHOST_BUF" ]]; then
        if [[ $_TURTLE_GHOST_STABLE -eq 1 ]]; then
            # Buffer stable for 2 ticks (~2s) → fire
            _TURTLE_GHOST_STABLE=0
            local writer; writer="$(_turtle_writer)"
            local outfile="$_TURTLE_GHOST_FILE"
            local json_buf
            json_buf=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$buf" 2>/dev/null) || return
            printf '{"action":"nl_to_shell","text":%s}\n' "$json_buf" \
                | python3 "$writer" --stdio 2>/dev/null \
                | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("data",{}).get("command",""))' \
                > "$outfile" 2>/dev/null &
            _TURTLE_GHOST_PID=$!
        else
            _TURTLE_GHOST_STABLE=1
        fi
    else
        # Buffer changed — reset and cancel any in-flight fetch
        _TURTLE_GHOST_BUF="$buf"
        _TURTLE_GHOST_STABLE=0
        if [[ -n "$_TURTLE_GHOST_SUGGESTION" ]]; then
            _TURTLE_GHOST_SUGGESTION=""
            zle -M ""
        fi
        if [[ $_TURTLE_GHOST_PID -gt 0 ]]; then
            kill "$_TURTLE_GHOST_PID" 2>/dev/null
            rm -f "$_TURTLE_GHOST_FILE"
            _TURTLE_GHOST_PID=0
        fi
    fi
}
zle -N _turtle_ghost_tick

# TRAPALRM fires every TMOUT seconds while the line editor is active.
# We set TMOUT=1 only if not already set to something smaller.
if [[ -z "${TMOUT:-}" || "${TMOUT:-0}" -gt 1 ]]; then
    TMOUT=1
fi

TRAPALRM() {
    # zle _turtle_ghost_tick is safe — zle ignores the call outside the editor
    zle _turtle_ghost_tick 2>/dev/null || true
}

fi  # end ANTHROPIC_API_KEY guard
