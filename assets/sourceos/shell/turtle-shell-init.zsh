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

    # Enrich context with git branch and project type
    local cwd="$PWD"
    local git_branch=""
    git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    local _turtle_ctx="cwd=$cwd"
    [[ -n "$git_branch" ]] && _turtle_ctx="${_turtle_ctx} git_branch=$git_branch"
    [[ -f "package.json" ]] && _turtle_ctx="${_turtle_ctx} project=node"
    [[ -f "Cargo.toml" ]] && _turtle_ctx="${_turtle_ctx} project=rust"
    [[ -f "go.mod" ]] && _turtle_ctx="${_turtle_ctx} project=go"
    [[ -f "requirements.txt" || -f "pyproject.toml" ]] && _turtle_ctx="${_turtle_ctx} project=python"
    [[ -f "Makefile" ]] && _turtle_ctx="${_turtle_ctx} has_makefile=true"

    local result
    result=$(turtle-agentctl nl-to-shell "$current_buffer" --context "$_turtle_ctx" 2>/dev/null | \
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

# ============================================================
# Always-on inline autosuggest (Warp "Next Command", fully local)
#   zsh-autosuggestions-style dimmed ghost text after the cursor, backed by
#   the FAST local `predict-command` history path (no model, no network, no
#   $/mo, no telemetry). Default-on; disable with TURTLE_AUTOSUGGEST=0.
#   Accept with → (forward-char at EOL), END, or Ctrl-E.
# ============================================================

if [[ "${TURTLE_AUTOSUGGEST:-1}" != "0" ]]; then

typeset -g _TURTLE_AS_SUGGESTION=""   # current ghost suffix (after cursor)
typeset -g _TURTLE_AS_LASTBUF=$'\0'   # buffer we last fetched for (de-dupe)

# Warm-daemon config. The always-on autosuggest hot path routes predict requests
# to a persistent agentd HTTP daemon (~5-15ms round-trip via curl) instead of
# cold-spawning `python3 turtle-agentd --stdio` per keystroke (~120-170ms,
# pure interpreter-startup overhead). Falls back to the cold path if the daemon
# can't be reached/started or curl is missing — the warm path is an optimization,
# not a hard dependency.
typeset -g _TURTLE_AS_HTTP_PORT="${TURTLE_AGENTD_HTTP_PORT:-7722}"
typeset -g _TURTLE_AS_HTTP_URL="http://127.0.0.1:${_TURTLE_AS_HTTP_PORT}"
typeset -g _TURTLE_AS_DAEMON_TRIED=""   # guard so we only try to spawn once/shell
typeset -g _TURTLE_AS_DAEMON_OK=""      # cached "daemon reachable" flag

# Resolve a callable agentctl once.
_turtle_agentctl() {
    local ctl="${0:A:h}/../bin/turtle-agentctl"
    [[ -x "$ctl" ]] || ctl="turtle-agentctl"
    echo "$ctl"
}

# Start the agentd HTTP daemon self-detached (--daemonize double-forks inside
# agentd so it outlives this shell regardless of job-control; macOS lacks setsid
# but agentd's own os.fork/os.setsid handles it). Returns immediately — never
# blocks the prompt. Invokes the daemon correctly whether `_turtle_writer`
# resolves to an absolute path (run via python3) or a bare PATH command (exec
# directly via its shebang — `python3 turtle-agentd` would fail because python
# doesn't PATH-resolve script names).
_turtle_as_spawn_daemon() {
    local writer; writer="$(_turtle_writer)"
    if [[ "$writer" == */* && -f "$writer" ]]; then
        python3 "$writer" --http "$_TURTLE_AS_HTTP_PORT" --daemonize >/dev/null 2>&1 &!
    else
        # Bare command on PATH: run it directly (shebang handles the interpreter).
        command "$writer" --http "$_TURTLE_AS_HTTP_PORT" --daemonize >/dev/null 2>&1 &!
    fi
}

# Lazy, idempotent: ensure a warm agentd HTTP daemon is reachable. Returns 0 if
# the warm path is usable (curl present + daemon answering /health), else 1.
# Never blocks shell startup: the spawn is detached and we only probe quickly.
_turtle_as_ensure_daemon() {
    # curl is required for the warm path.
    command -v curl >/dev/null 2>&1 || return 1
    # Fast positive cache: once we've confirmed reachability, trust it.
    [[ -n "$_TURTLE_AS_DAEMON_OK" ]] && return 0
    # Already reachable (e.g. launchd-managed or another shell started it)?
    if curl -s --max-time 0.15 "${_TURTLE_AS_HTTP_URL}/health" >/dev/null 2>&1; then
        _TURTLE_AS_DAEMON_OK=1
        return 0
    fi
    # Only attempt to spawn once per shell so we never thrash on a broken setup.
    if [[ -n "$_TURTLE_AS_DAEMON_TRIED" ]]; then
        return 1
    fi
    _TURTLE_AS_DAEMON_TRIED=1
    _turtle_as_spawn_daemon
    # Bounded wait for it to come up. Cold python startup binds the port in
    # ~300ms, so probe a bit past that — but the whole thing runs detached at
    # init (and the first synchronous fetch falls back to cold once, then warm).
    local i
    for i in $(seq 1 16); do
        sleep 0.05
        if curl -s --max-time 0.15 "${_TURTLE_AS_HTTP_URL}/health" >/dev/null 2>&1; then
            _TURTLE_AS_DAEMON_OK=1
            return 0
        fi
    done
    return 1
}

# Warm predict over the daemon (no python spawn). Echoes the completion suffix.
# Returns non-zero (and prints nothing) if the warm path is unavailable so the
# caller can fall back to the cold --stdio path.
_turtle_as_predict_warm() {
    local buf="$1" cwd="$2"
    _turtle_as_ensure_daemon || return 1
    local body resp
    # Build the JSON request safely (zsh quoting of buffer/cwd via python is
    # avoided on the hot path; do minimal escaping of " and \ inline).
    local eb="${buf//\\/\\\\}"; eb="${eb//\"/\\\"}"
    local ec="${cwd//\\/\\\\}"; ec="${ec//\"/\\\"}"
    body="{\"action\":\"predict_command\",\"partial\":\"${eb}\",\"cwd\":\"${ec}\"}"
    resp=$(curl -s --max-time 0.15 -X POST "${_TURTLE_AS_HTTP_URL}/stdio" \
                -H 'Content-Type: application/json' -d "$body" 2>/dev/null) || return 1
    [[ -n "$resp" ]] || return 1
    # Extract data.completion without spawning python: zsh-native JSON-ish pluck.
    # The daemon returns a flat object; match the completion field.
    local comp="${resp#*\"completion\": \"}"
    if [[ "$comp" == "$resp" ]]; then
        # try compact form ("completion":")
        comp="${resp#*\"completion\":\"}"
        [[ "$comp" == "$resp" ]] && return 0   # no completion key -> empty
    fi
    comp="${comp%%\"*}"
    # Unescape the common JSON escapes we might see.
    comp="${comp//\\\"/\"}"; comp="${comp//\\\\/\\}"
    print -r -- "$comp"
    return 0
}

# Clear any displayed ghost text.
_turtle_as_clear() {
    _TURTLE_AS_SUGGESTION=""
    POSTDISPLAY=""
    region_highlight=("${(@)region_highlight:#*TURTLE_AS*}")
}

# Fetch + render the ghost suffix for the current BUFFER. Fast history path,
# hard-timeboxed so a slow predict can never jank typing.
_turtle_as_fetch() {
    # Only suggest when typing at end of a non-empty line.
    if [[ -z "$BUFFER" || $CURSOR -ne ${#BUFFER} ]]; then
        _turtle_as_clear
        return
    fi
    local suffix=""
    # FAST PATH: route to the warm agentd daemon (HTTP via curl, ~5-15ms, no
    # python spawn). Falls through to the cold --stdio path only if the daemon
    # is unreachable / curl is missing.
    if suffix="$(_turtle_as_predict_warm "$BUFFER" "$PWD" 2>/dev/null)"; then
        :
    else
        # COLD FALLBACK: spawn `turtle-agentctl --stdio` (~120-170ms). Slower but
        # keeps autosuggest working when no daemon/curl is available.
        local ctl; ctl="$(_turtle_agentctl)"
        # `timeout` if available keeps the hot path bounded.
        local _to=""
        if command -v timeout >/dev/null 2>&1; then _to="timeout 0.2"; fi
        suffix=$(
            $_to "$ctl" --stdio predict-command partial="$BUFFER" cwd="$PWD" 2>/dev/null \
            | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin); print(d.get("data",{}).get("completion",""), end="")
except Exception:
    pass' 2>/dev/null
        )
    fi
    if [[ -n "$suffix" ]]; then
        _TURTLE_AS_SUGGESTION="$suffix"
        POSTDISPLAY="$suffix"
        # Dim the ghost region (fg=8 / 'bright black').
        region_highlight+=("${#BUFFER} $(( ${#BUFFER} + ${#suffix} )) fg=8 TURTLE_AS")
    else
        _turtle_as_clear
    fi
}

# Fires on every redraw (each keystroke) — non-blocking & fast.
# De-dupe: only re-fetch when the buffer actually changed since last redraw,
# so cursor moves / pure redraws cost nothing.
_turtle_as_redraw() {
    if [[ "$BUFFER" == "$_TURTLE_AS_LASTBUF" ]]; then
        # Re-render existing ghost (zsh clears POSTDISPLAY between redraws).
        if [[ -n "$_TURTLE_AS_SUGGESTION" && $CURSOR -eq ${#BUFFER} && -n "$BUFFER" ]]; then
            POSTDISPLAY="$_TURTLE_AS_SUGGESTION"
            region_highlight+=("${#BUFFER} $(( ${#BUFFER} + ${#_TURTLE_AS_SUGGESTION} )) fg=8 TURTLE_AS")
        fi
        return
    fi
    _TURTLE_AS_LASTBUF="$BUFFER"
    _turtle_as_fetch
}
zle -N zle-line-pre-redraw _turtle_as_redraw 2>/dev/null || true

# Accept the whole suggestion (used by → / END / Ctrl-E at EOL).
_turtle_as_accept() {
    if [[ -n "$_TURTLE_AS_SUGGESTION" && $CURSOR -eq ${#BUFFER} ]]; then
        BUFFER="$BUFFER$_TURTLE_AS_SUGGESTION"
        CURSOR=${#BUFFER}
        _turtle_as_clear
        return 0
    fi
    return 1
}

# Right-arrow / Ctrl-E / End: accept ghost if at EOL, else fall through.
_turtle_as_forward_or_accept() {
    if [[ $CURSOR -eq ${#BUFFER} && -n "$_TURTLE_AS_SUGGESTION" ]]; then
        _turtle_as_accept
    else
        zle .forward-char
    fi
}
_turtle_as_eol_or_accept() {
    if [[ $CURSOR -eq ${#BUFFER} && -n "$_TURTLE_AS_SUGGESTION" ]]; then
        _turtle_as_accept
    else
        zle .end-of-line
    fi
}
zle -N _turtle_as_forward_or_accept
zle -N _turtle_as_eol_or_accept
bindkey '^[[C' _turtle_as_forward_or_accept   # right arrow
bindkey '^F'   _turtle_as_forward_or_accept   # ctrl-f
bindkey '^E'   _turtle_as_eol_or_accept       # ctrl-e
bindkey '^[[F' _turtle_as_eol_or_accept       # End
bindkey '^[OF' _turtle_as_eol_or_accept       # End (alt encoding)

# Optional: accept-and-execute the ghost on a dedicated chord (ALT+Enter).
_turtle_as_accept_execute() {
    _turtle_as_accept && zle .accept-line
}
zle -N _turtle_as_accept_execute
bindkey '^[^M' _turtle_as_accept_execute      # ALT+Enter

# Warm the daemon up front so the very first keystroke is already fast. We start
# it self-detached (--daemonize) directly — not via _turtle_as_ensure_daemon in a
# subshell, which couldn't share the reachable-flag back and would double-spawn.
# This is fire-and-forget and never blocks shell startup; the first predict's
# own ensure step re-probes /health and caches the result in this shell.
if command -v curl >/dev/null 2>&1; then
    if ! curl -s --max-time 0.1 "${_TURTLE_AS_HTTP_URL}/health" >/dev/null 2>&1; then
        _TURTLE_AS_DAEMON_TRIED=1
        _turtle_as_spawn_daemon
    else
        _TURTLE_AS_DAEMON_OK=1
    fi
fi

fi  # end TURTLE_AUTOSUGGEST

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

# ============================================================
# Auto-performance timing (preexec/precmd — no user action needed)
# ============================================================

_turtle_preexec_timing() {
    _TURTLE_PERF_START=$EPOCHREALTIME
    _TURTLE_PERF_CMD="$1"
}

_turtle_precmd_timing() {
    local rc=$?
    if [[ -n "$_TURTLE_PERF_START" && -n "$_TURTLE_PERF_CMD" ]]; then
        local elapsed_ms=$(( int(($EPOCHREALTIME - $_TURTLE_PERF_START) * 1000) ))
        # Record async (fire-and-forget, no delay to prompt)
        if (( elapsed_ms > 100 )); then
            (turtle-agentctl --stdio perf-record "$_TURTLE_PERF_CMD" "$elapsed_ms" >/dev/null 2>&1 &)
        fi
        # macOS notification for long commands (> 10s)
        if (( elapsed_ms > 10000 )); then
            local cmd_short="${_TURTLE_PERF_CMD:0:40}"
            (osascript -e "display notification \"${cmd_short} (${elapsed_ms}ms)\" with title \"TurtleTerm: Command done\"" 2>/dev/null &)
        fi
        _TURTLE_LAST_ELAPSED=$elapsed_ms
        _TURTLE_PERF_START=""
        _TURTLE_PERF_CMD=""
    fi
}

# Install hooks (avoid duplicates)
if (( ${preexec_functions[(I)_turtle_preexec_timing]} == 0 )); then
    preexec_functions+=(_turtle_preexec_timing)
fi
if (( ${precmd_functions[(I)_turtle_precmd_timing]} == 0 )); then
    precmd_functions+=(_turtle_precmd_timing)
fi

# ============================================================
# Right-side prompt (RPROMPT) showing plan step + perf
# ============================================================

# Right-side prompt: active plan step + last command time
_turtle_rprompt() {
    local rp=""
    # Show active plan step if any (cached, don't call agentd every prompt)
    if [[ -n "$_TURTLE_PLAN_STEP" ]]; then
        rp="%F{yellow}⟳ step ${_TURTLE_PLAN_STEP}%f "
    fi
    # Show last command time if > 1s
    if [[ -n "$_TURTLE_LAST_ELAPSED" ]] && (( _TURTLE_LAST_ELAPSED > 1000 )); then
        local secs=$(( _TURTLE_LAST_ELAPSED / 1000 ))
        rp="${rp}%F{240}${secs}s%f"
    fi
    echo -n "$rp"
}

# Track elapsed for RPROMPT
_turtle_precmd_rprompt() {
    if [[ -n "$_TURTLE_PERF_START" ]]; then
        _TURTLE_LAST_ELAPSED=$(( int(($EPOCHREALTIME - $_TURTLE_PERF_START) * 1000) ))
    fi
}

if (( ${precmd_functions[(I)_turtle_precmd_rprompt]} == 0 )); then
    precmd_functions+=(_turtle_precmd_rprompt)
fi

# Set RPROMPT if user hasn't set it
if [[ -z "$RPROMPT" ]]; then
    RPROMPT='$(_turtle_rprompt)'
    setopt PROMPT_SUBST 2>/dev/null
fi
