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
