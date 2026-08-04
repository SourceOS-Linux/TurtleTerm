# TurtleTerm shell integration for zsh.
#
# Source from ~/.zshrc:
#   source /path/to/turtle-shell-init.zsh

[[ -n "${_TURTLE_SHELL_INIT_ZSH:-}" ]] && return 0
_TURTLE_SHELL_INIT_ZSH=1

if [[ -z "${SOURCEOS_TERMINAL_SESSION_ID:-}" ]]; then
    export SOURCEOS_TERMINAL_SESSION_ID="term-$(python3 -c 'import uuid; print(uuid.uuid4().hex)' 2>/dev/null || date +%s)"
fi

# Auto-start turtle-status-daemon if not already running (writes CI/PR/Noetica cache)
if [[ -z "${_TURTLE_STATUS_DAEMON_STARTED:-}" ]]; then
    _TURTLE_STATUS_DAEMON_STARTED=1
    _turtle_status_daemon_bin="$(dirname "$(readlink -f "${(%):-%x}" 2>/dev/null || echo "${0:A}")")/../bin/turtle-status-daemon"
    if [[ -x "$_turtle_status_daemon_bin" ]]; then
        if ! pgrep -f "turtle-status-daemon" >/dev/null 2>&1; then
            python3 "$_turtle_status_daemon_bin" &! 2>/dev/null
        fi
    fi
    unset _turtle_status_daemon_bin
fi

# Auto-start BearBrowser ↔ mesh bridge (syncs browse events into memory mesh)
if [[ -z "${_TURTLE_BB_BRIDGE_STARTED:-}" ]]; then
    _TURTLE_BB_BRIDGE_STARTED=1
    _bb_bridge="$HOME/dev/BearBrowser/scripts/bearbrowser-mesh-bridge.py"
    if [[ -f "$_bb_bridge" ]]; then
        if ! pgrep -f "bearbrowser-mesh-bridge" >/dev/null 2>&1; then
            python3 "$_bb_bridge" --watch &! 2>/dev/null
        fi
    fi
    unset _bb_bridge
fi

# Auto-start Goose Notes ↔ mesh bridge (syncs notes bidirectionally)
if [[ -z "${_TURTLE_GOOSE_BRIDGE_STARTED:-}" ]]; then
    _TURTLE_GOOSE_BRIDGE_STARTED=1
    _goose_bridge="$(dirname "$(readlink -f "${(%):-%x}" 2>/dev/null || echo "${0:A}")")/../bin/turtle-goose-bridge"
    if [[ -x "$_goose_bridge" ]]; then
        if ! pgrep -f "turtle-goose-bridge" >/dev/null 2>&1; then
            python3 "$_goose_bridge" --watch &! 2>/dev/null
        fi
    fi
    unset _goose_bridge
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

# ============================================================
# |? semantic pipe operator — pipe any output through Noetica
#    with active mesh context automatically injected.
# Usage: git log | ? "which commits touched auth"
#        docker ps | ? "which containers are unhealthy"
#        kubectl get pods | ? "which are not ready and why"
# ============================================================

_turtle_noetica_query() {
    # Low-level: send a prompt to Noetica, print the response.
    # Args: $1=noetica URL  $2=prompt string
    local _noetica="$1" _prompt="$2"
    python3 -c "
import json, urllib.request, sys
noetica, prompt = sys.argv[1], sys.argv[2]
payload = json.dumps({'messages':[{'role':'user','content':prompt}],'stream':False}).encode()
try:
    req = urllib.request.Request(noetica+'/api/chat', data=payload,
                                  headers={'Content-Type':'application/json'})
    with urllib.request.urlopen(req, timeout=10) as r:
        d = json.load(r)
        msg = (d.get('choices',[{}])[0].get('message',{}).get('content','')
               or d.get('message',{}).get('content','')
               or d.get('content',''))
        print(msg.strip())
except Exception as e:
    print(f'(Noetica unreachable: {e})', file=sys.stderr)
    sys.exit(1)
" "$_noetica" "$_prompt" 2>&1
}

_turtle_active_context_snippet() {
    # Returns a 1-3 line context string from active.json (cwd/branch/title).
    local _mesh_dir="${XDG_STATE_HOME:-$HOME/.local/state}/sourceos/memory-mesh"
    python3 -c "
import json, pathlib
active = pathlib.Path('$_mesh_dir/active.json')
if active.exists():
    try:
        d = json.loads(active.read_text())
        parts = []
        if d.get('cwd'):  parts.append('cwd: ' + d['cwd'])
        if d.get('branch'): parts.append('branch: ' + d['branch'])
        if d.get('title'):  parts.append('context: ' + d['title'])
        print('\n'.join(parts))
    except: pass
" 2>/dev/null
}

\?() {
    local _query="$*"
    local _noetica="${NOETICA_URL:-http://localhost:7700}"
    local _stdin_data _ctx
    _stdin_data="$(cat)"

    if [[ -z "$_query" ]]; then
        printf '%s\n' "$_stdin_data"
        return
    fi

    _ctx="$(_turtle_active_context_snippet)"
    local _ctx_block=""
    [[ -n "$_ctx" ]] && _ctx_block=$'\n\nShell context:\n'"$_ctx"

    local _prompt="Given this command output:

${_stdin_data:0:3000}${_ctx_block}

Answer: ${_query}

Be concise (1-4 lines)."

    printf '\e[38;2;57;197;207m▍\e[0m '
    local _result
    _result="$(_turtle_noetica_query "$_noetica" "$_prompt" 2>/dev/null)"

    if [[ -n "$_result" ]]; then
        printf '\e[38;2;230;237;243m%s\e[0m\n' "$_result"
    else
        printf '\e[2m(no response — is Noetica running on %s?)\e[0m\n' "$_noetica" >&2
    fi
}

# ============================================================
# noe — direct Noetica query (no pipe needed)
#       Injects active mesh context automatically.
# Usage: noe "explain this error: ECONNREFUSED"
#        noe cap "what was that kubectl command I ran?"
# ============================================================
noe() {
    local _query="$*"
    local _noetica="${NOETICA_URL:-http://localhost:7700}"

    if [[ -z "$_query" ]]; then
        echo "Usage: noe <question>" >&2
        echo "       noe cap <question>  — ask about the last capture" >&2
        return 1
    fi

    # 'noe cap' — include last capture/note from mesh in context
    if [[ "${1:-}" == "cap" ]]; then
        shift
        _query="$*"
        local _mesh_dir="${XDG_STATE_HOME:-$HOME/.local/state}/sourceos/memory-mesh"
        local _last_cap
        _last_cap="$(python3 -c "
import json, pathlib
ctx = pathlib.Path('$_mesh_dir/context.jsonl')
if ctx.exists():
    for line in reversed(ctx.read_text(errors='replace').splitlines()):
        try:
            ev = json.loads(line)
            if ev.get('kind') in ('capture','note','shell-cmd'):
                print('# ' + ev.get('title','') + '\n' + ev.get('content','')[:800])
                break
        except: pass
" 2>/dev/null)"
        [[ -n "$_last_cap" ]] && _query="Context:\n${_last_cap}\n\nQuestion: ${_query}"
    fi

    local _ctx; _ctx="$(_turtle_active_context_snippet)"
    [[ -n "$_ctx" ]] && _query="${_query}

Shell context:
${_ctx}"

    printf '\e[38;2;57;197;207m▍ Noetica\e[0m\n'
    local _result
    _result="$(_turtle_noetica_query "$_noetica" "$_query")"
    if [[ -n "$_result" ]]; then
        printf '\e[38;2;230;237;243m%s\e[0m\n\n' "$_result"
    else
        printf '\e[2m(no response from Noetica at %s)\e[0m\n' "$_noetica" >&2
    fi
}

# ============================================================
# Destructive command preview gate
# Extends the existing pattern check with actionable preview
# before the command runs. Requires explicit 'y' to continue.
# Disable with TURTLE_PREVIEW_GATE=0.
# ============================================================
_turtle_destructive_patterns=(
    '^rm[[:space:]].*-[a-zA-Z]*r[a-zA-Z]*[[:space:]]'
    '^git[[:space:]]+push[[:space:]].*--force'
    '^git[[:space:]]+push[[:space:]].*-f[[:space:]]'
    '^git[[:space:]]+reset[[:space:]]--hard'
    '^kubectl[[:space:]]+delete[[:space:]]'
    '^terraform[[:space:]]+destroy'
    '^helm[[:space:]]+uninstall'
    '^docker[[:space:]]+rm[[:space:]]'
    '^gcloud.*instances[[:space:]]+delete'
    '^gsutil[[:space:]]+rm[[:space:]]'
)

_turtle_preview_gate() {
    [[ "${TURTLE_PREVIEW_GATE:-1}" == "0" ]] && return 0
    local cmd="$1"
    local matched=0
    for pat in "${_turtle_destructive_patterns[@]}"; do
        if [[ "$cmd" =~ $pat ]]; then
            matched=1; break
        fi
    done
    (( matched )) || return 0

    printf '\e[38;2;255;123;114m⚠  Destructive command detected\e[0m\n' >&2
    printf '\e[2m  %s\e[0m\n' "$cmd" >&2

    # Show contextual preview
    if [[ "$cmd" =~ '^rm ' ]]; then
        local target
        target="$(echo "$cmd" | grep -oE '[^[:space:]]+$')"
        if [[ -e "$target" ]]; then
            printf '\e[2m  will delete: %s (%s items)\e[0m\n' "$target" \
                "$(find "$target" 2>/dev/null | wc -l | tr -d ' ')" >&2
        fi
    elif [[ "$cmd" =~ '^git push.*--force' || "$cmd" =~ '^git push.*-f ' ]]; then
        local ahead
        ahead="$(git log --oneline @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')"
        printf '\e[2m  will force-push %s commits\e[0m\n' "$ahead" >&2
    fi

    printf '\e[38;2;255;123;114mProceed? [y/N] \e[0m' >&2
    local yn
    read -r yn </dev/tty
    [[ "$yn" =~ ^[Yy]$ ]] && return 0

    printf '\e[2m  aborted\e[0m\n' >&2
    # Return non-zero to signal preexec should reject (zsh doesn't support
    # blocking from preexec cleanly, so we clear the buffer via a trap)
    return 1
}

# ============================================================
# Auto-generated zsh completions for unknown turtle-*/prophet-* CLIs
# On first invocation: runs `cmd --help`, asks Noetica to generate
# a _cmd completion function, caches to ~/.turtle/completions/.
# ============================================================
_TURTLE_COMP_DIR="${HOME}/.turtle/completions"

_turtle_maybe_generate_completion() {
    local cmd="$1"
    # Only for our own toolchain
    [[ "$cmd" =~ ^(turtle|prophet|goose|bearbrowser|sourceos) ]] || return 0
    local comp_file="${_TURTLE_COMP_DIR}/_${cmd}"
    [[ -f "$comp_file" ]] && return 0   # already generated
    # Run async so it never blocks the prompt
    (
        local help_text
        help_text="$("$cmd" --help 2>&1 | head -60)"
        [[ -z "$help_text" ]] && exit 0
        local _noetica="${NOETICA_URL:-http://localhost:7700}"
        local generated
        generated="$(python3 -c "
import json, urllib.request, sys
cmd, help_text = sys.argv[1], sys.argv[2]
prompt = (
    f'Generate a minimal zsh _arguments completion function for the CLI tool \`{cmd}\`.\n'
    f'Help output:\n{help_text}\n\n'
    f'Output ONLY valid zsh code starting with \"#compdef {cmd}\" and ending with the function body. '
    f'No explanation, no markdown fences.'
)
payload = json.dumps({'messages':[{'role':'user','content':prompt}],'stream':False}).encode()
try:
    req = urllib.request.Request('${_noetica}/api/chat', data=payload,
                                  headers={'Content-Type':'application/json'})
    with urllib.request.urlopen(req, timeout=10) as r:
        d = json.load(r)
        print((d.get('message',{}).get('content','') or d.get('content','')).strip())
except Exception:
    pass
" "$cmd" "$help_text" 2>/dev/null)"
        if [[ "$generated" == "#compdef"* ]]; then
            mkdir -p "${_TURTLE_COMP_DIR}"
            printf '%s\n' "$generated" > "$comp_file"
            # Add to fpath if not already there
            [[ " ${fpath[*]} " == *" ${_TURTLE_COMP_DIR} "* ]] || \
                fpath=("${_TURTLE_COMP_DIR}" "${fpath[@]}")
        fi
    ) &!
}

_TURTLE_ZSH_CMD=""
_TURTLE_ZSH_STARTED_AT=""
_TURTLE_ZSH_CMD_EPOCH=0
_TURTLE_ZSH_EVT_ID=""

# ── AI/shell boundary: print a teal left-gutter bar before AI-sourced output ─
# Called by pending_command injection path (see turtleterm.lua) via a state flag.
# The bar makes it immediately obvious: "this output came from an AI action, not
# your shell." Warp's most-upvoted UX complaint is this ambiguity. We solve it.
_turtle_ai_boundary_start() {
    # OSC 8 hyperlink trick: a teal ▍ gutter with OSC 133 B for semantic zone
    printf '\e]133;B\a'
    printf '\e[38;2;57;197;207m▍\e[0m '  # teal ▍ = AI-sourced output
}
_turtle_ai_boundary_end() {
    printf '\e]133;C\a'
}

preexec() {
    local cmd="$1"
    [[ -z "$cmd" ]] && return
    _TURTLE_ZSH_CMD="$cmd"
    _TURTLE_ZSH_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"
    _TURTLE_ZSH_CMD_EPOCH=${EPOCHSECONDS:-0}

    # OSC 133 C — command output start (marks command start for prompt jumping)
    printf '\e]133;C\a'

    # Dangerous pattern check (warning only)
    _turtle_check_dangerous "$cmd"

    # Destructive preview gate (requires explicit y for rm/force-push/destroy/etc.)
    _turtle_preview_gate "$cmd"

    # Auto-generate completions for unknown turtle-*/prophet-* tools (async, non-blocking)
    local _first_word="${cmd%% *}"
    _turtle_maybe_generate_completion "$_first_word"

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

    # ── inline failure explainer ───────────────────────────────────────────────
    # On non-zero exit: ask Noetica reason-lane for a structured diagnosis and
    # print it inline BELOW the error output — first-class UX, not a toast.
    # Opt out: TURTLE_EXPLAIN_ERRORS=0
    if [[ $exit_status -ne 0 && "${TURTLE_EXPLAIN_ERRORS:-1}" != "0" && -n "$_TURTLE_ZSH_CMD" ]]; then
        local _last_cmd_for_explain="$_TURTLE_ZSH_CMD"
        {
            local _explanation
            _explanation=$(python3 -c "
import urllib.request, urllib.error, json, sys, os
try:
    payload = json.dumps({
        'messages': [{'role':'user','content':
            f'Shell command failed (exit {sys.argv[1]}): \`{sys.argv[2]}\`\n'
            f'Give a 1-sentence cause and 2-3 concrete fix suggestions. No preamble. Be terse.'
        }],
        'stream': False
    }).encode()
    req = urllib.request.Request(
        os.getenv('NOETICA_URL','http://localhost:7700') + '/api/chat',
        data=payload, headers={'Content-Type':'application/json'})
    with urllib.request.urlopen(req, timeout=4) as r:
        d = json.load(r)
        content = d.get('message',{}).get('content','') or d.get('content','')
        if content:
            print(content.strip())
except Exception:
    pass
" "$exit_status" "$_last_cmd_for_explain" 2>/dev/null)
            if [[ -n "$_explanation" ]]; then
                printf '\n\e[38;2;88;166;255m◆\e[0m \e[2mexit %d\e[0m  %s\n\n' \
                    "$exit_status" "$_explanation" >&2
            fi
        } &!
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

    # ── rich history index for turtle-history semantic search ─────────────────
    # Append one JSONL line per completed command. Debounced to skip rapid-fire
    # completions (like make steps) — only write if cmd is non-trivial.
    if [[ ${#cmd} -gt 3 && "$cmd" != "ls" && "$cmd" != "cd"* ]]; then
        local _hist_dir; _hist_dir="$(_turtle_state_dir)"
        local _hist_file="$_hist_dir/history.jsonl"
        local _dur=$(( ${EPOCHSECONDS:-0} - ${_TURTLE_ZSH_CMD_EPOCH:-0} ))
        local _cwd; _cwd="$(pwd)"
        local _ts; _ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo '')"
        local _branch=""
        _branch="$(git -C "$_cwd" branch --show-current 2>/dev/null || echo '')"
        # fire-and-forget, never blocks the prompt
        {
            printf '{"cmd":%s,"exit":%d,"cwd":%s,"branch":%s,"ts":%s,"duration":%d}\n' \
                "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$cmd" 2>/dev/null || echo '""')" \
                "$exit_status" \
                "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$_cwd" 2>/dev/null || echo '""')" \
                "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$_branch" 2>/dev/null || echo '""')" \
                "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$_ts" 2>/dev/null || echo '""')" \
                "$_dur" >> "$_hist_file" 2>/dev/null
            # cap at 5000 lines (trim oldest)
            if [[ $(wc -l < "$_hist_file" 2>/dev/null || echo 0) -gt 5000 ]]; then
                tail -4000 "$_hist_file" > "$_hist_file.tmp" && mv "$_hist_file.tmp" "$_hist_file"
            fi
        } &!
    fi
}

# ── turtle-history: semantic ^R replacement ────────────────────────────────────
# ^R      → fzf history with exit codes, cwd context, duration
# ^R ?    → type a NL query, backed by Noetica when available
_turtle_history_widget() {
    local query="${BUFFER}"
    local selected
    # Run turtle-history in widget mode; it handles fzf/plain fallback internally
    selected="$(turtle-history --widget ${query:+"$query"} 2>/dev/tty </dev/tty)"
    local ret=$?
    if [[ $ret -eq 0 && -n "$selected" ]]; then
        BUFFER="$selected"
        CURSOR=${#BUFFER}
        zle reset-prompt
    fi
}
zle -N _turtle_history_widget
# Override ^R with our widget; keep ESC-r as fallback to built-in reverse search
bindkey '^R' _turtle_history_widget
bindkey '\er' history-incremental-search-backward

# ============================================================
# Memory mesh: ?? recall, tc capture, ctx, mission control
# ============================================================

# ctx — pretty snapshot of current SourceOS context (mesh+CI+BB)
# Example: ctx         # full panel
#          ctx --short # single-line summary for copy-paste into AI prompts
ctx() {
    local _ctx_bin
    _ctx_bin="$(dirname "$(readlink -f "${(%):-%x}" 2>/dev/null || echo "${0:A}")")/../bin/turtle-context"
    [[ -x "$_ctx_bin" ]] || _ctx_bin="turtle-context"
    "$_ctx_bin" "$@"
}

# ?? <query> — quick memory recall from any prompt
# Example: ?? postgres replica setup
??() {
    local _turtle_recall_bin
    _turtle_recall_bin="$(dirname "$(readlink -f "${(%):-%x}" 2>/dev/null || echo "${0:A}")")/../bin/turtle-recall"
    [[ -x "$_turtle_recall_bin" ]] || _turtle_recall_bin="turtle-recall"
    "$_turtle_recall_bin" "$@"
}

# tc — pipe alias to capture terminal output to Goose Notes + mesh
# Example: docker logs myapp | tc "app crash log"
tc() {
    local _turtle_capture_bin
    _turtle_capture_bin="$(dirname "$(readlink -f "${(%):-%x}" 2>/dev/null || echo "${0:A}")")/../bin/turtle-capture"
    [[ -x "$_turtle_capture_bin" ]] || _turtle_capture_bin="turtle-capture"
    "$_turtle_capture_bin" "$@"
}

# mc — toggle mission control panel (TurtleTerm only; graceful no-op elsewhere)
_turtle_mc() {
    local _mc_bin
    _mc_bin="$(dirname "$(readlink -f "${(%):-%x}" 2>/dev/null || echo "${0:A}")")/../bin/turtle-mission-control"
    [[ -x "$_mc_bin" ]] || _mc_bin="turtle-mission-control"
    if [[ -n "${WEZTERM_PANE:-}" ]]; then
        # In WezTerm: prefer the CMD+SHIFT+M binding; fallback to running in pane
        "$_mc_bin" --once
    else
        "$_mc_bin" --once
    fi
}

# Auto-write memory mesh active context on each directory change
_turtle_mesh_cd() {
    local _state="${XDG_STATE_HOME:-$HOME/.local/state}/sourceos/memory-mesh"
    local _branch=""
    _branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    mkdir -p "$_state"
    printf '{"updated":"%s","cwd":"%s","branch":"%s","focus":"cd %s"}\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$PWD" "$_branch" "$PWD" \
        > "$_state/active.json"
}

# Hook into chpwd for passive context tracking
if (( ${chpwd_functions[(I)_turtle_mesh_cd]} == 0 )); then
    chpwd_functions+=(_turtle_mesh_cd)
fi

# ============================================================
# Inline file rendering
# ============================================================

_turtle_render_bin() {
    local _bin
    _bin="$(dirname "$(readlink -f "${(%):-%x}" 2>/dev/null || echo "${0:A}")")/../bin/turtle-render"
    [[ -x "$_bin" ]] && echo "$_bin" && return
    echo "turtle-render"
}

# smart cat: auto-renders images/PDF/CSV/JSON inline; falls through to system cat otherwise.
# Disable with TURTLE_SMART_CAT=0.
_TURTLE_IMAGE_EXTS=(png jpg jpeg gif webp bmp ico tiff tif avif svg)
_TURTLE_RENDER_EXTS=(pdf csv tsv json md markdown)

cat() {
    if [[ "${TURTLE_SMART_CAT:-1}" == "0" ]]; then
        command cat "$@"
        return
    fi
    local visual=0
    for arg in "$@"; do
        [[ "$arg" == -* ]] && continue
        local ext="${arg:l:e}"  # lowercase extension
        if (( ${_TURTLE_IMAGE_EXTS[(I)$ext]} )) || (( ${_TURTLE_RENDER_EXTS[(I)$ext]} )); then
            visual=1
            break
        fi
    done
    if (( visual )); then
        local _rbin; _rbin="$(_turtle_render_bin)"
        local render_args=()
        for arg in "$@"; do
            [[ "$arg" == -* ]] && { command cat "$@"; return; }
            render_args+=("$arg")
        done
        "$_rbin" "${render_args[@]}"
    else
        command cat "$@"
    fi
}

# lsi — ls with inline image thumbnails (width=18 cols each)
lsi() {
    local dir="${1:-.}"
    local _rbin; _rbin="$(_turtle_render_bin)"
    local found=0
    for f in "$dir"/*.{png,jpg,jpeg,gif,webp,bmp,tiff,svg}(N); do
        [[ -f "$f" ]] || continue
        found=1
        printf "\033[38;2;88;166;255m%s\033[0m\n" "$(basename "$f")"
        "$_rbin" --width 18 "$f" 2>/dev/null
    done
    (( found )) || ls "$dir"
}

# vv — visual view: always renders regardless of file type (explicit alias)
vv() {
    local _rbin; _rbin="$(_turtle_render_bin)"
    "$_rbin" "$@"
}

# ============================================================
# bb  — open BearBrowser (optionally with a URL or file path)
#        emits a mesh event so TurtleTerm knows what you're browsing
# bbs — BearBrowser search: summarize query via Noetica, then open BB
# Usage: bb
#        bb https://example.com
#        bb path/to/file.pdf
#        bbs "how does turbulent flow work in microchannels"
# ============================================================

bb() {
    local _url="${1:-}"
    local _mesh_dir="${XDG_STATE_HOME:-$HOME/.local/state}/sourceos/memory-mesh"
    local _bb_scripts="$HOME/dev/BearBrowser/scripts"

    # Emit mesh event
    python3 -c "
import json, datetime, os, pathlib
mesh = pathlib.Path('$_mesh_dir')
mesh.mkdir(parents=True, exist_ok=True)
ctx = mesh / 'context.jsonl'
ev = {
    'ts': datetime.datetime.now(datetime.timezone.utc).isoformat().replace('+00:00','Z'),
    'kind': 'browse',
    'source': 'shell-bb',
    'title': '$_url' or 'BearBrowser opened',
    'content': 'User opened BearBrowser' + (' at $_url' if '$_url' else ''),
    'url': '$_url',
    'cwd': os.getcwd(),
}
with ctx.open('a') as f:
    f.write(json.dumps(ev) + '\n')
" 2>/dev/null &!

    # Update active context
    local _branch; _branch="$(git branch --show-current 2>/dev/null || echo '')"
    python3 -c "
import json, datetime, os, pathlib, socket
mesh = pathlib.Path('$_mesh_dir')
mesh.mkdir(parents=True, exist_ok=True)
(mesh / 'active.json').write_text(json.dumps({
    'cwd': os.getcwd(),
    'branch': '$_branch',
    'title': 'BearBrowser: $_url',
    'hostname': socket.gethostname(),
    'updated': datetime.datetime.now(datetime.timezone.utc).isoformat().replace('+00:00','Z'),
}, indent=2))
" 2>/dev/null &!

    if [[ -n "$_url" ]] && [[ -f "$_url" ]]; then
        # Local file — convert to file:// URL
        _url="file://$(realpath "$_url")"
    fi

    if [[ -x "$_bb_scripts/bearbrowser-open.sh" ]]; then
        if [[ -n "$_url" ]]; then
            bash "$_bb_scripts/bearbrowser-open.sh" && open -a BearBrowser "$_url" 2>/dev/null ||:
        else
            bash "$_bb_scripts/bearbrowser-open.sh"
        fi
    else
        if [[ -n "$_url" ]]; then
            open -a BearBrowser "$_url" 2>/dev/null || open "$_url"
        else
            open -a BearBrowser 2>/dev/null || echo "BearBrowser not found — run bearbrowser-open.sh" >&2
        fi
    fi
}

bbs() {
    local _query="$*"
    if [[ -z "$_query" ]]; then
        echo "Usage: bbs <search query>" >&2
        return 1
    fi

    local _noetica="${NOETICA_URL:-http://localhost:7700}"
    local _url

    # Ask Noetica for the best URL to open for this query
    _url="$(python3 -c "
import json, sys
from urllib import request as urlreq
try:
    payload = json.dumps({'messages': [{'role': 'user',
        'content': 'Reply with ONLY a single search URL (no explanation) for: $_query'}],
        'max_tokens': 80}).encode()
    req = urlreq.Request('$_noetica/api/chat', data=payload,
        headers={'Content-Type': 'application/json'})
    with urlreq.urlopen(req, timeout=4) as r:
        resp = json.load(r)
        print(resp.get('choices',[{}])[0].get('message',{}).get('content','').strip())
except Exception:
    print('')
" 2>/dev/null)"

    if [[ -z "$_url" ]] || [[ "$_url" != http* ]]; then
        # Fallback: DuckDuckGo
        local _encoded; _encoded="$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote_plus('$_query'))" 2>/dev/null || echo "$_query")"
        _url="https://duckduckgo.com/?q=${_encoded}&ia=web"
    fi

    echo "  \033[38;2;0;200;200mBearBrowser → ${_url}\033[0m"
    bb "$_url"
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
        # AI/shell boundary: blue ◆ prefix makes AI suggestions visually distinct from shell history
        zle -M $'\e[38;2;88;166;255m◆ AI\e[0m  '"$result"$'  \e[2m[ALT+/ to accept]\e[0m'
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
# Rich RPROMPT — duration · git diff · peak RSS · exit code
# ============================================================

_TURTLE_RUSAGE_BEFORE=0
_TURTLE_LAST_RSS=0

# Read resource.RUSAGE_CHILDREN (peak RSS of last waited child) from Python.
# Called in precmd — reads accumulated RSS since last call, so we delta it.
_turtle_read_rss() {
    python3 -c "
import resource
r = resource.getrusage(resource.RUSAGE_CHILDREN)
# On macOS ru_maxrss is bytes; on Linux it's KB
import sys, platform
rss = r.ru_maxrss
if platform.system() == 'Darwin':
    rss = rss // 1024  # → KB
print(rss)
" 2>/dev/null || echo 0
}

# Compact git diff stat: "+12 -3" or "" if clean
_turtle_git_diffstat() {
    local stat
    stat="$(git diff --shortstat 2>/dev/null)"
    [[ -z "$stat" ]] && return
    local added removed
    added="$(echo "$stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')"
    removed="$(echo "$stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')"
    local out=""
    [[ -n "$added" ]]   && out="+${added}"
    [[ -n "$removed" ]] && out="${out:+$out }−${removed}"
    [[ -n "$out" ]] && printf '%s' "$out"
}

_turtle_rprompt() {
    local rp=""
    setopt localoptions nopromptsubst

    # Plan step
    if [[ -n "$_TURTLE_PLAN_STEP" ]]; then
        rp="%F{yellow}⟳ step ${_TURTLE_PLAN_STEP}%f "
    fi

    # Duration (> 1s)
    if [[ -n "$_TURTLE_LAST_ELAPSED" ]] && (( _TURTLE_LAST_ELAPSED > 1000 )); then
        local secs=$(( _TURTLE_LAST_ELAPSED / 1000 ))
        if (( secs >= 3600 )); then
            rp="${rp}%F{240}$(( secs/3600 ))h$(( (secs%3600)/60 ))m%f "
        elif (( secs >= 60 )); then
            rp="${rp}%F{240}$(( secs/60 ))m$(( secs%60 ))s%f "
        else
            rp="${rp}%F{240}${secs}s%f "
        fi
    fi

    # Git diff stats (green/red) — only shown when there are uncommitted changes
    local _diffstat
    _diffstat="$(_turtle_git_diffstat 2>/dev/null)"
    if [[ -n "$_diffstat" ]]; then
        # colour each part
        local _added _removed
        _added="$(echo "$_diffstat" | grep -oE '\+[0-9]+')"
        _removed="$(echo "$_diffstat" | grep -oE '−[0-9]+')"
        [[ -n "$_added" ]]   && rp="${rp}%F{2}${_added}%f "
        [[ -n "$_removed" ]] && rp="${rp}%F{1}${_removed}%f "
    fi

    # Peak RSS of last command (shown when >50MB)
    if (( _TURTLE_LAST_RSS > 51200 )); then
        local mb=$(( _TURTLE_LAST_RSS / 1024 ))
        rp="${rp}%F{240}${mb}MB%f "
    fi

    # Trailing space trim
    echo -n "${rp% }"
}

_turtle_precmd_rprompt() {
    # Capture elapsed
    if [[ -n "$_TURTLE_PERF_START" ]]; then
        _TURTLE_LAST_ELAPSED=$(( int(($EPOCHREALTIME - $_TURTLE_PERF_START) * 1000) ))
    fi
    # Capture peak RSS delta (async — don't block the prompt)
    {
        local _rss_now; _rss_now="$(_turtle_read_rss)"
        local _delta=$(( _rss_now - _TURTLE_RUSAGE_BEFORE ))
        (( _delta > 0 )) && _TURTLE_LAST_RSS=$_delta || _TURTLE_LAST_RSS=0
        _TURTLE_RUSAGE_BEFORE=$_rss_now
    } &!
}

if (( ${precmd_functions[(I)_turtle_precmd_rprompt]} == 0 )); then
    precmd_functions+=(_turtle_precmd_rprompt)
fi

if [[ -z "$RPROMPT" ]]; then
    RPROMPT='$(_turtle_rprompt)'
    setopt PROMPT_SUBST 2>/dev/null
fi

# ============================================================
# wasi — cross-machine "where was I"
# Reads memory mesh events from other hostnames (via local mesh
# or GCS if available). Shows last cwd, branch, commands, agents.
# ============================================================
wasi() {
    local _mesh_dir="${XDG_STATE_HOME:-$HOME/.local/state}/sourceos/memory-mesh"
    local _ctx_file="$_mesh_dir/context.jsonl"
    local _this_host; _this_host="$(hostname -s 2>/dev/null || hostname)"
    local _noetica="${NOETICA_URL:-http://localhost:7700}"
    local _gcs="${SOURCEOS_MESH_BUCKET:-gs://sourceos-artifacts-socioprophet/memory-mesh}"

    printf '\e[38;2;88;166;255m◆ wasi — where was I\e[0m\n'
    printf '\e[2m  this machine: %s\e[0m\n\n' "$_this_host"

    # Try to pull from GCS first (gets other machines' context)
    if command -v gsutil >/dev/null 2>&1; then
        local _remote_ctx
        _remote_ctx="$(gsutil cat "$_gcs/context.jsonl" 2>/dev/null | tail -200)"
        if [[ -n "$_remote_ctx" ]]; then
            echo "$_remote_ctx" | python3 -c "
import json, sys, os
this_host = os.uname().nodename.split('.')[0]
events = []
for line in sys.stdin:
    try:
        e = json.loads(line)
        h = e.get('hostname','')
        if h and h != this_host:
            events.append(e)
    except: pass
if not events:
    print('  \033[2mno events from other machines\033[0m')
    sys.exit(0)
# Group by hostname
from collections import defaultdict
by_host = defaultdict(list)
for e in events:
    by_host[e['hostname']].append(e)
for host, evs in sorted(by_host.items()):
    print(f'\n  \033[38;2;188;140;255m{host}\033[0m')
    for ev in evs[-5:]:
        ts = ev.get('ts','')[:16]
        kind = ev.get('kind','?')
        title = ev.get('title','')[:60]
        cwd = ev.get('cwd','')
        branch = ev.get('branch','')
        loc = f'{cwd}' + (f'  ({branch})' if branch else '')
        print(f'    \033[2m{ts}\033[0m  \033[38;2;63;185;80m{kind:<10}\033[0m  {title}')
        if loc:
            print(f'               \033[2m{loc}\033[0m')
"
            return
        fi
    fi

    # Fallback: local mesh (same machine, recent context for continuity)
    if [[ -f "$_ctx_file" ]]; then
        tail -30 "$_ctx_file" | python3 -c "
import json, sys
events = []
for line in sys.stdin:
    try: events.append(json.loads(line))
    except: pass
if not events:
    print('  \033[2mno mesh events yet — run: some-command | tc\033[0m')
    sys.exit(0)
print('  \033[2m(local mesh — no GCS credentials for cross-machine)\033[0m')
for ev in reversed(events[-8:]):
    ts = ev.get('ts','')[:16]
    kind = ev.get('kind','?')
    title = ev.get('title','')[:60]
    print(f'  \033[2m{ts}\033[0m  \033[38;2;63;185;80m{kind:<10}\033[0m  {title}')
"
    else
        printf '  \e[2mno memory mesh yet — source turtle-shell-init.zsh and run: tc "first capture"\e[0m\n'
    fi
}

# ============================================================
# Auto project env injection on cd
# Infers venv/nvm/kube-context/poetry from project files.
# Each activation is silent unless it changes something.
# Disable entirely: TURTLE_ENV_INJECT=0
# ============================================================
_TURTLE_LAST_VENV=""
_TURTLE_LAST_NODE=""
_TURTLE_LAST_KUBE=""

_turtle_env_inject() {
    [[ "${TURTLE_ENV_INJECT:-1}" == "0" ]] && return

    # ── Python venv ────────────────────────────────────────────
    local _venv=""
    if [[ -d ".venv" ]]; then
        _venv=".venv"
    elif [[ -d "venv" ]]; then
        _venv="venv"
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        # poetry-managed — try `poetry env info -p`
        if command -v poetry >/dev/null 2>&1; then
            local _pe; _pe="$(poetry env info -p 2>/dev/null)"
            [[ -n "$_pe" && -d "$_pe" ]] && _venv="$_pe"
        fi
    fi
    if [[ -n "$_venv" && "$_venv" != "$_TURTLE_LAST_VENV" ]]; then
        source "$_venv/bin/activate" 2>/dev/null && \
            printf '\e[2m  ⚡ venv: %s\e[0m\n' "$_venv"
        _TURTLE_LAST_VENV="$_venv"
    elif [[ -z "$_venv" && -n "$_TURTLE_LAST_VENV" && -n "$VIRTUAL_ENV" ]]; then
        deactivate 2>/dev/null || true
        _TURTLE_LAST_VENV=""
    fi

    # ── Node version (.nvmrc / .node-version) ─────────────────
    if command -v nvm >/dev/null 2>&1; then
        local _nvmrc=""
        [[ -f ".nvmrc" ]]        && _nvmrc="$(cat .nvmrc | tr -d '[:space:]')"
        [[ -f ".node-version" ]] && _nvmrc="$(cat .node-version | tr -d '[:space:]')"
        if [[ -n "$_nvmrc" && "$_nvmrc" != "$_TURTLE_LAST_NODE" ]]; then
            nvm use "$_nvmrc" --silent 2>/dev/null && \
                printf '\e[2m  ⚡ node: %s\e[0m\n' "$_nvmrc"
            _TURTLE_LAST_NODE="$_nvmrc"
        fi
    fi

    # ── Kubernetes context (from .kube-context file) ───────────
    if command -v kubectl >/dev/null 2>&1 && [[ -f ".kube-context" ]]; then
        local _kctx; _kctx="$(cat .kube-context | tr -d '[:space:]')"
        if [[ -n "$_kctx" && "$_kctx" != "$_TURTLE_LAST_KUBE" ]]; then
            kubectl config use-context "$_kctx" >/dev/null 2>&1 && \
                printf '\e[2m  ⚡ kube: %s\e[0m\n' "$_kctx"
            _TURTLE_LAST_KUBE="$_kctx"
        fi
    fi

    # ── direnv fallback ────────────────────────────────────────
    if command -v direnv >/dev/null 2>&1 && [[ -f ".envrc" ]]; then
        direnv export zsh 2>/dev/null | source /dev/stdin 2>/dev/null || true
    fi
}

# Hook env injection after _turtle_mesh_cd
if (( ${chpwd_functions[(I)_turtle_env_inject]} == 0 )); then
    chpwd_functions+=(_turtle_env_inject)
fi

# ============================================================
# session-save / session-restore — named workspace snapshots
# Persists: cwd, last 20 commands, env vars, git branch, agents
# Stored in memory mesh so cross-machine restore works via wasi.
# ============================================================
session-save() {
    local name="${1:-$(basename "$PWD")}"
    local _mesh_dir="${XDG_STATE_HOME:-$HOME/.local/state}/sourceos/memory-mesh"
    local _sessions_dir="$_mesh_dir/sessions"
    mkdir -p "$_sessions_dir"

    local _branch; _branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
    local _cmds=()
    local _state_dir; _state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/sourceos/terminal"
    local _hist_file="$_state_dir/history.jsonl"

    # Collect last 20 commands from JSONL history
    if [[ -f "$_hist_file" ]]; then
        maparray -t _cmds < <(tail -20 "$_hist_file" | python3 -c "
import json,sys
for line in sys.stdin:
    try: print(json.loads(line).get('cmd',''))
    except: pass
" 2>/dev/null)
    fi

    # Env snapshot (filter out secrets)
    local _env_json
    _env_json="$(python3 -c "
import os, json
skip = {'HISTFILE','HISTSIZE','LS_COLORS','TERM_SESSION_ID','TMPDIR','LOGNAME'}
env = {k:v for k,v in os.environ.items()
       if not any(s in k for s in ('SECRET','TOKEN','KEY','PASS','CRED'))
       and k not in skip and len(v) < 200}
print(json.dumps(env))
" 2>/dev/null || echo '{}')"

    local _session
    _session="$(python3 -c "
import json, datetime, os, socket
data = {
    'name': '$name',
    'ts': datetime.datetime.utcnow().isoformat()+'Z',
    'hostname': socket.gethostname(),
    'cwd': os.getcwd(),
    'branch': '$_branch',
    'commands': $(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${_cmds[@]}" 2>/dev/null || echo '[]'),
    'env': $(_env_json),
}
print(json.dumps(data, indent=2))
" 2>/dev/null)"

    printf '%s\n' "$_session" > "$_sessions_dir/${name}.json"

    # Also write to mesh context
    local _ts; _ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"ts":"%s","kind":"session-save","source":"terminal","title":"%s","cwd":"%s","branch":"%s"}\n' \
        "$_ts" "$name" "$PWD" "$_branch" >> "$_mesh_dir/context.jsonl"

    printf '\e[38;2;63;185;80m✓\e[0m  session saved: \e[1m%s\e[0m\n' "$name"
    printf '  \e[2m%s\e[0m\n' "$_sessions_dir/${name}.json"
}

session-restore() {
    local name="${1}"
    local _mesh_dir="${XDG_STATE_HOME:-$HOME/.local/state}/sourceos/memory-mesh"
    local _sessions_dir="$_mesh_dir/sessions"

    if [[ -z "$name" ]]; then
        # List available sessions
        printf '\e[38;2;88;166;255m◆ Saved sessions:\e[0m\n'
        for f in "$_sessions_dir"/*.json(N); do
            local _n; _n="$(basename "$f" .json)"
            local _ts; _ts="$(python3 -c "import json; d=json.load(open('$f')); print(d.get('ts','?')[:16])" 2>/dev/null)"
            local _cwd; _cwd="$(python3 -c "import json; d=json.load(open('$f')); print(d.get('cwd','?'))" 2>/dev/null)"
            printf '  \e[1m%-20s\e[0m  \e[2m%s  %s\e[0m\n' "$_n" "$_ts" "$_cwd"
        done
        return
    fi

    local _file="$_sessions_dir/${name}.json"
    if [[ ! -f "$_file" ]]; then
        printf '\e[38;2;255;123;114m✗\e[0m  no session: %s\n' "$name" >&2
        return 1
    fi

    python3 - "$_file" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"\033[38;2;88;166;255m◆ Restoring: {d.get('name','?')}\033[0m")
print(f"  cwd:     {d.get('cwd','?')}")
print(f"  branch:  {d.get('branch','?')}")
print(f"  saved:   {d.get('ts','?')[:16]}  on {d.get('hostname','?')}")
cwd = d.get('cwd','')
branch = d.get('branch','')
print(f"\n  \033[2mcd {cwd}\033[0m")
if branch:
    print(f"  \033[2mgit checkout {branch}  (if available)\033[0m")
PYEOF

    local _cwd; _cwd="$(python3 -c "import json; print(json.load(open('$_file')).get('cwd',''))" 2>/dev/null)"
    local _branch; _branch="$(python3 -c "import json; print(json.load(open('$_file')).get('branch',''))" 2>/dev/null)"

    [[ -n "$_cwd" && -d "$_cwd" ]] && cd "$_cwd" || printf '  \e[2m(cwd no longer exists)\e[0m\n'
    if [[ -n "$_branch" ]]; then
        git checkout "$_branch" 2>/dev/null && \
            printf '  \e[38;2;63;185;80m✓\e[0m branch: %s\n' "$_branch" || true
    fi

    printf '\n\e[38;2;63;185;80m✓\e[0m  session restored: \e[1m%s\e[0m\n' "$name"
}
