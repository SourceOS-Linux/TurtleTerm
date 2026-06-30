# TurtleTerm shell integration for fish.
#
# Source from ~/.config/fish/config.fish:
#   source /path/to/turtle-shell-init.fish
#
# Or symlink into ~/.config/fish/conf.d/turtle.fish

if set -q _TURTLE_SHELL_INIT_FISH
    exit 0
end
set -g _TURTLE_SHELL_INIT_FISH 1

if not set -q SOURCEOS_TERMINAL_SESSION_ID
    set -gx SOURCEOS_TERMINAL_SESSION_ID (python3 -c 'import uuid; print("term-"+uuid.uuid4().hex)' 2>/dev/null; or echo "term-"(date +%s))
end

set -gx SOURCEOS_TERMINAL_FRONTEND (set -q SOURCEOS_TERMINAL_FRONTEND; and echo $SOURCEOS_TERMINAL_FRONTEND; or echo "turtle-term")
set -gx SOURCEOS_WORKSPACE (set -q SOURCEOS_WORKSPACE; and echo $SOURCEOS_WORKSPACE; or echo "default")

function _turtle_writer
    set -l writer (dirname (status filename))/../bin/turtle-agentd
    if not test -x $writer
        set writer turtle-agentd
    end
    echo $writer
end

function _turtle_state_dir
    if set -q XDG_STATE_HOME
        echo "$XDG_STATE_HOME/sourceos/terminal"
    else
        echo "$HOME/.local/state/sourceos/terminal"
    end
end

function _turtle_check_dangerous
    set -l cmd $argv[1]
    set -l dangerous 0
    if string match -rq 'rm\s+-rf\s+[/~]' $cmd; or \
       string match -rq 'git\s+push\s+.*--force' $cmd; or \
       string match -rq 'git\s+push\s+-f' $cmd; or \
       string match -rq 'DROP\s+TABLE' $cmd; or \
       string match -rq '\|\s*sh$' $cmd; or \
       string match -rq 'sudo\s+rm\s+-rf' $cmd; or \
       string match -rq 'kill\s+-9\s+1$' $cmd
        set dangerous 1
    end
    if test $dangerous -eq 1
        printf '\e[33m⚠  TurtleTerm policy: dangerous pattern detected — review before running\e[0m\n' >&2
        set -l writer (_turtle_writer)
        python3 $writer --stdio >/dev/null 2>&1 &
        echo '{"action":"ingest_event","event":{"event_type":"policy.dangerous_pattern","session_id":"'$SOURCEOS_TERMINAL_SESSION_ID'","shell":"fish"}}' | python3 $writer --stdio >/dev/null 2>&1 &
    end
end

set -g _TURTLE_FISH_CMD ""
set -g _TURTLE_FISH_STARTED_AT ""
set -g _TURTLE_FISH_EVT_ID ""
set -g _TURTLE_FISH_START_EPOCH 0

function _turtle_fish_preexec --on-event fish_preexec
    set -g _TURTLE_FISH_CMD $argv[1]
    set -g _TURTLE_FISH_STARTED_AT (date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null; or echo "")
    set -g _TURTLE_FISH_START_EPOCH (date +%s 2>/dev/null; or echo 0)
    set -g _TURTLE_FISH_EVT_ID (python3 -c 'import uuid; print("evt_"+uuid.uuid4().hex)' 2>/dev/null; or echo "evt_0")

    # OSC 133 C — command output start
    printf '\e]133;C\a'

    _turtle_check_dangerous $argv[1]

    set -l writer (_turtle_writer)
    set -l cmd_json (python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' $argv[1] 2>/dev/null; or echo '"'$argv[1]'"')

    python3 $writer --stdio 2>/dev/null <<EOF
{
  "action": "ingest_event",
  "event": {
    "event_id": "$_TURTLE_FISH_EVT_ID",
    "event_type": "command.started",
    "session_id": "$SOURCEOS_TERMINAL_SESSION_ID",
    "workspace_id": "$SOURCEOS_WORKSPACE",
    "actor_id": "human:local-user",
    "frontend": "$SOURCEOS_TERMINAL_FRONTEND",
    "cwd": "(pwd)",
    "command": $cmd_json,
    "started_at": "$_TURTLE_FISH_STARTED_AT",
    "shell": "fish"
  }
}
EOF
end

# ============================================================
# AI ghost-text — two modes:
#   1. Explicit: ALT+/ fires immediately (synchronous)
#   2. Debounced: CTRL+SPACE (same underlying function)
# Only active when ANTHROPIC_API_KEY is set or TURTLE_GHOST_TEXT=1
# ============================================================

if set -q ANTHROPIC_API_KEY; or test "$TURTLE_GHOST_TEXT" = "1"

function _turtle_ai_complete
    set -l buf (commandline)
    test -z "$buf"; and return

    set -l writer (_turtle_writer)
    set -l json_buf (python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' $buf 2>/dev/null; or echo '"'$buf'"')
    set -l result (printf '{"action":"nl_to_shell","text":%s}\n' $json_buf \
        | python3 $writer --stdio 2>/dev/null \
        | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("data",{}).get("command",""))' 2>/dev/null)
    if test -n "$result"; and test "$result" != "$buf"
        commandline -r $result
        commandline -f repaint
    end
end

if status is-interactive
    bind \e/ _turtle_ai_complete           # ALT+/
    bind \e\  _turtle_ai_complete          # ALT+SPACE (fallback)
end

# Debounced background ghost-text (fish has no TRAPALRM, so we use
# fish_prompt event to consume results from a background fetch launched
# after each keystroke by the key binding below).

set -g _TURTLE_GHOST_BUF ""
set -g _TURTLE_GHOST_PID 0
set -g _TURTLE_GHOST_FILE /tmp/turtle-fish-ghost-$fish_pid.txt

function __turtle_ghost_fetch
    # Called by ALT+G; launches background fetch, result applied on next prompt
    set -l buf (commandline)
    test (string length $buf) -lt 4; and return
    test "$buf" = "$_TURTLE_GHOST_BUF"; and return   # same input, skip

    set -g _TURTLE_GHOST_BUF $buf
    # Kill previous in-flight fetch
    if test $_TURTLE_GHOST_PID -gt 0
        kill $_TURTLE_GHOST_PID 2>/dev/null
        rm -f $_TURTLE_GHOST_FILE
        set -g _TURTLE_GHOST_PID 0
    end

    set -l writer (_turtle_writer)
    set -l json_buf (python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' $buf 2>/dev/null)
    printf '{"action":"nl_to_shell","text":%s}\n' $json_buf \
        | python3 $writer --stdio 2>/dev/null \
        | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("data",{}).get("command",""))' \
        > $_TURTLE_GHOST_FILE 2>/dev/null &
    set -g _TURTLE_GHOST_PID $last_pid
end

function __turtle_consume_ghost --on-event fish_prompt
    # Consume result on next prompt draw after a background fetch
    test $_TURTLE_GHOST_PID -eq 0; and return
    not test -f $_TURTLE_GHOST_FILE; and return
    # Check if process exited
    if not kill -0 $_TURTLE_GHOST_PID 2>/dev/null
        set -l result (cat $_TURTLE_GHOST_FILE 2>/dev/null)
        rm -f $_TURTLE_GHOST_FILE
        set -g _TURTLE_GHOST_PID 0
        set -g _TURTLE_GHOST_BUF ""
        if test -n "$result"
            # Print hint below prompt (non-destructive; user must press ALT+/ to accept)
            printf '\e[90m  AI▸ %s\e[0m\n' (string sub -l 80 $result) >&2
        end
    end
end

if status is-interactive
    bind \eg __turtle_ghost_fetch          # ALT+G: background ghost fetch
end

trap 'rm -f $_TURTLE_GHOST_FILE' EXIT

end  # end ANTHROPIC_API_KEY guard

# ============================================================
# Local context-aware autosuggest (Warp "Next Command", fully local)
#   fish already ships native history autosuggestions, so we ENHANCE rather
#   than fight it: a binding that pulls the TurtleTerm `predict-command`
#   completion (cwd/context-weighted, no model, no telemetry) and inserts it.
#   Default-on; disable with TURTLE_AUTOSUGGEST=0.
#   Bound to ALT+L (accept local prediction). Fast history path only.
# ============================================================

if test "$TURTLE_AUTOSUGGEST" != "0"

function _turtle_agentctl
    set -l ctl (dirname (status filename))/../bin/turtle-agentctl
    if not test -x $ctl
        set ctl turtle-agentctl
    end
    echo $ctl
end

function _turtle_predict_accept
    set -l buf (commandline)
    test -z "$buf"; and return
    set -l ctl (_turtle_agentctl)
    set -l to
    if command -v timeout >/dev/null 2>&1
        set to timeout 0.2
    end
    set -l suffix ($to $ctl --stdio predict-command partial="$buf" cwd=(pwd) 2>/dev/null \
        | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin); print(d.get("data",{}).get("completion",""), end="")
except Exception:
    pass' 2>/dev/null)
    if test -n "$suffix"
        commandline -i -- $suffix
        commandline -f repaint
    end
end

if status is-interactive
    bind \el _turtle_predict_accept        # ALT+L: accept local prediction
end

end  # end TURTLE_AUTOSUGGEST

function _turtle_fish_postexec --on-event fish_postexec
    set -l exit_status $status
    set -l completed_at (date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null; or echo "")

    # OSC 133 D + A — end command, start prompt
    printf '\e]133;D;%d\a' $exit_status
    printf '\e]133;A\a'

    # Write exit code + timing for status bar
    set -l state_dir (_turtle_state_dir)
    mkdir -p $state_dir 2>/dev/null
    printf '%d' $exit_status > "$state_dir/last_exit" 2>/dev/null
    if test $_TURTLE_FISH_START_EPOCH -gt 0
        set -l _now (date +%s 2>/dev/null; or echo 0)
        set -l _elapsed (math $_now - $_TURTLE_FISH_START_EPOCH)
        printf '%d' $_elapsed > "$state_dir/last_duration" 2>/dev/null
    end

    # Long command notification
    if test -n "$_TURTLE_FISH_CMD"; and test $_TURTLE_FISH_START_EPOCH -gt 0
        set -l now (date +%s 2>/dev/null; or echo 0)
        set -l elapsed (math $now - $_TURTLE_FISH_START_EPOCH)
        set -l threshold (set -q TURTLE_NOTIFY_THRESHOLD; and echo $TURTLE_NOTIFY_THRESHOLD; or echo 10)
        if test "$threshold" != "0"; and test $elapsed -ge $threshold
            set -l short_cmd (string sub -l 50 $_TURTLE_FISH_CMD)
            osascript -e "display notification \"$short_cmd ($elapsed\s, exit $exit_status)\" with title \"TurtleTerm\"" 2>/dev/null &
        end
    end

    test -z "$_TURTLE_FISH_CMD"; and return

    set -l cmd $_TURTLE_FISH_CMD
    set -l started_at $_TURTLE_FISH_STARTED_AT
    set -l event_id $_TURTLE_FISH_EVT_ID"_completed"
    set -l writer (_turtle_writer)
    set -l cmd_json (python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' $cmd 2>/dev/null; or echo '"'$cmd'"')

    set -g _TURTLE_FISH_CMD ""
    set -g _TURTLE_FISH_EVT_ID ""
    set -g _TURTLE_FISH_START_EPOCH 0

    python3 $writer --stdio 2>/dev/null <<EOF
{
  "action": "ingest_event",
  "event": {
    "event_id": "$event_id",
    "event_type": "command.completed",
    "session_id": "$SOURCEOS_TERMINAL_SESSION_ID",
    "workspace_id": "$SOURCEOS_WORKSPACE",
    "actor_id": "human:local-user",
    "frontend": "$SOURCEOS_TERMINAL_FRONTEND",
    "cwd": "(pwd)",
    "command": $cmd_json,
    "exit_status": $exit_status,
    "started_at": "$started_at",
    "completed_at": "$completed_at",
    "shell": "fish"
  }
}
EOF
end
