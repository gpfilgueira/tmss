#!/usr/bin/env bash

session="$1"
dir="$2"
setup_script="$3"

if [[ -z "$session" || -z "$dir" || -z "$setup_script" ]]; then
    echo "Usage: $0 <session_name> <dir> <setup_script>"
    exit 1
fi

# Check if tmux server is running at all
if ! pgrep tmux >/dev/null; then
    # No tmux server - create new session and attach
    tmux new-session -s "$session" -c "$dir" -d
    # Export for setup script
    export SESSION="$session"
    export DIR="$dir"
    if [[ -x "$setup_script" ]]; then
        "$setup_script"
    else
        echo "Setup script not found or not executable: $setup_script"
    fi
    tmux attach -t "$session"
    exit 0
fi

# tmux is running
if tmux has-session -t="$session" 2>/dev/null; then
    # Session exists
    if [[ -z "$TMUX" ]]; then
        # Not inside tmux, attach directly
        tmux attach -t "$session"
    else
        # Inside tmux, switch client without attaching twice
        tmux switch-client -t "$session"
    fi
else
    # Session doesn't exist yet, create detached
    tmux new-session -d -s "$session" -c "$dir"
    export SESSION="$session"
    export DIR="$dir"


    for i in {1..10}; do
        if tmux has-session -t="$session" 2>/dev/null; then
            break
        fi
        sleep 0.3
    done

    if [[ -x "$setup_script" ]]; then
        "$setup_script"
    else
        echo "Setup script not found or not executable: $setup_script"
    fi
    # Attach or switch after creation
    if [[ -z "$TMUX" ]]; then
        tmux attach -t "$session"
    else
        tmux switch-client -t "$session"
    fi
fi
