#!/usr/bin/env bash
# tmss-spear: Quick tmux session selector inspired by Harpoon

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
TMSS_STATE_DIR="$STATE_HOME/tmss"
mkdir -p "$TMSS_STATE_DIR"

SPEAR_FILE="$TMSS_STATE_DIR/spear-sessions.txt"
action="$1"

if [[ ! -f "$SPEAR_FILE" ]]; then
    echo "Spear file not found: $SPEAR_FILE" >&2
    exit 1
fi

mapfile -t live_sessions < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

valid_sessions=()
while IFS= read -r session; do
    if printf "%s\n" "${live_sessions[@]}" | grep -qxF "$session"; then
        valid_sessions+=("$session")
    fi
done < "$SPEAR_FILE"

if [[ "$action" == "jump-forward" || "$action" == "jump-backward" ]]; then
    current=$(tmux display-message -p '#S')
    index=-1
    for i in "${!valid_sessions[@]}"; do
        [[ "${valid_sessions[$i]}" == "$current" ]] && index=$i && break
    done

    [[ $index -lt 0 ]] && exit 1

    if [[ "$action" == "jump-forward" ]]; then
        next_index=$(( (index + 1) % ${#valid_sessions[@]} ))
    else
        next_index=$(( (index - 1 + ${#valid_sessions[@]}) % ${#valid_sessions[@]} ))
    fi

    target="${valid_sessions[$next_index]}"
else
    target=""
    if [[ "$action" =~ ^[0-9]+$ ]]; then
        idx=$((action - 1))
        target="${valid_sessions[$idx]}"
    else
        for sess in "${valid_sessions[@]}"; do
            [[ "$sess" == "$action" ]] && target="$sess" && break
        done
    fi
fi

if [[ -n "$target" ]]; then
    if [[ -n "$TMUX" ]]; then
        tmux switch-client -c "$TMUX_PANE" -t "$target"
    else
        tmux attach -t "$target"
    fi
else
    exec >/dev/null 2>&1
    exit 0
fi
