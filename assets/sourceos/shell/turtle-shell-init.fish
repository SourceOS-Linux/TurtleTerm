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

set -g _TURTLE_FISH_CMD ""
set -g _TURTLE_FISH_STARTED_AT ""
set -g _TURTLE_FISH_EVT_ID ""

function _turtle_fish_preexec --on-event fish_preexec
    set -g _TURTLE_FISH_CMD $argv[1]
    set -g _TURTLE_FISH_STARTED_AT (date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null; or echo "")
    set -g _TURTLE_FISH_EVT_ID (python3 -c 'import uuid; print("evt_"+uuid.uuid4().hex)' 2>/dev/null; or echo "evt_0")

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

    test -z "$_TURTLE_FISH_CMD"; and return

    set -l cmd $_TURTLE_FISH_CMD
    set -l started_at $_TURTLE_FISH_STARTED_AT
    set -l event_id $_TURTLE_FISH_EVT_ID"_completed"
    set -l writer (_turtle_writer)
    set -l cmd_json (python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' $cmd 2>/dev/null; or echo '"'$cmd'"')

    set -g _TURTLE_FISH_CMD ""
    set -g _TURTLE_FISH_EVT_ID ""

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
