#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

EDITOR_CMD=nvim

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
TMSS_STATE_DIR="$STATE_HOME/tmss"
mkdir -p "$TMSS_STATE_DIR"

SPEAR_FILE="$TMSS_STATE_DIR/spear-sessions.txt"

# If no list yet, populate with current sessions
if [ ! -s "$SPEAR_FILE" ]; then
    tmux list-sessions -F '#{session_name}' > "$SPEAR_FILE"
fi

while true; do
    # Get current live sessions
    mapfile -t live_sessions < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

    touch "$SPEAR_FILE"

    # Keep only sessions still alive (preserve user-defined order)
    mapfile -t updated_sessions < <(
        while IFS= read -r session; do
            [[ " ${live_sessions[*]} " == *" $session "* ]] && echo "$session"
        done < "$SPEAR_FILE"
    )

    # Append new live sessions not yet tracked
    for sess in "${live_sessions[@]}"; do
        if ! printf "%s\n" "${updated_sessions[@]}" | grep -qxF "$sess"; then
            updated_sessions+=("$sess")
        fi
    done

    # Save back to file
    printf "%s\n" "${updated_sessions[@]}" > "$SPEAR_FILE"
    mapfile -t valid_sessions < "$SPEAR_FILE"

    result=$(printf "%s\n" "${valid_sessions[@]}" | \
        fzf \
        --prompt="tmss-spear > " \
        --preview='tmux list-windows -t {}' \
        --preview-window=right:60% \
        --expect=enter,ctrl-d,ctrl-r,ctrl-s \
        --bind "ctrl-e:execute($EDITOR_CMD \"$SPEAR_FILE\" > /dev/tty)+reload(cat \"$SPEAR_FILE\")" \
        --bind "ctrl-o:execute(sort -u \"$SPEAR_FILE\" -o \"$SPEAR_FILE\")+reload(cat \"$SPEAR_FILE\")" \
        --bind 'ctrl-s:abort'
    )

    key=$(head -1 <<< "$result")
    session=$(tail -n +2 <<< "$result" | head -1)

    # Handle key with no session selected
    case "$key" in
        ctrl-s)
            "${SCRIPT_DIR}/tmss-fd.sh"
            exit 0
            ;;
    esac

    [[ -z "$session" ]] && exit 1

    case "$key" in
        enter)
            if [ -n "$TMUX" ]; then
                tmux switch-client -c "$TMUX_PANE" -t "$session"
            else
                tmux attach-session -t "$session"
            fi
            break
            ;;
        ctrl-d)
            tmux kill-session -t "$session"
            sed -i "/^$session$/d" "$SPEAR_FILE"
            ;;
        ctrl-r)
            read -rp "New name for session '$session': " new_name
            [ -n "$new_name" ] || continue
            tmux rename-session -t "$session" "$new_name"
            sed -i "s/^$session\$/$new_name/" "$SPEAR_FILE"
            ;;
    esac
done
