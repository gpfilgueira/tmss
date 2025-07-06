#!/usr/bin/env bash

# File setup
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TMSS_CONFIG_DIR="$CONFIG_HOME/tmss"
LIST_FILE="$TMSS_CONFIG_DIR/tmss-preconf-list.sh"
mkdir -p "$TMSS_CONFIG_DIR/preconf-sessions"

# Load preconf session map
declare -A preconf_sessions
[[ -f "$LIST_FILE" ]] && source "$LIST_FILE"

# Create the directory if it doesn't exist
selection=$(
  (
    find ~ -mindepth 0 -maxdepth 1 \
      \( \
        -path "$HOME/Applications" -o \
        -path "$HOME/.config" -o \
        -path "$HOME/Desktop" -o \
        -path "$HOME/.local" -o \
        -path "$HOME/Documents" -o \
        -path "$HOME/nw" -o \
        -path "$HOME/notes" -o \
        -path "$HOME/Pictures" -o \
        -path "$HOME/tmp" \
      \) -prune -o \( -type d -print \)

    find "$HOME/Applications" "$HOME/.config" "$HOME/Desktop" "$HOME/.local" "$HOME/Documents" \
         "$HOME/nw" "$HOME/notes" "$HOME/Pictures" "$HOME/tmp" \
         -mindepth 0 -maxdepth 4 \
         \( -path "$HOME/nw/vpn/latitude/secrets" -prune \) -o -type d -print

    find "$HOME/university" "$HOME/.dotfiles" "$HOME/projects" -type d -print
 ) | fzf --bind 'ctrl-s:abort' --expect=ctrl-s
)

key=$(head -n1 <<< "$selection")
dir=$(tail -n +2 <<< "$selection")

# Handle the ctrl-s bind
if [[ "$key" == "ctrl-s" ]]; then
    "$(dirname "${BASH_SOURCE[0]}")/tmss-manage.sh"
    exit 0
fi

[[ -z "$dir" ]] && exit 1

if [[ ${preconf_sessions["$dir"]+_} ]]; then
    session_name="${preconf_sessions[$dir]}"
    setup_script="$TMSS_CONFIG_DIR/preconf-sessions/$(echo "$session_name" | tr '[:upper:]' '[:lower:]').sh"
    "$(dirname "${BASH_SOURCE[0]}")/tmss-preconfs.sh" "$session_name" "$dir" "$setup_script"
    exit 0
fi

basename_dir=$(basename "$dir" | tr . _)
basename_dir="${basename_dir// /_}"

if ! pgrep tmux >/dev/null; then
    tmux new-session -s "$basename_dir" -c "$dir"
elif [[ -z $TMUX ]]; then
    if tmux has-session -t="$basename_dir" 2>/dev/null; then
        tmux attach -t "$basename_dir"
    else
        tmux new-session -s "$basename_dir" -c "$dir"
        tmux attach -t "$basename_dir"
    fi
else
    if tmux has-session -t="$basename_dir" 2>/dev/null; then
        tmux switch-client -t "$basename_dir"
    else
        tmux new-session -ds "$basename_dir" -c "$dir"
        tmux switch-client -t "$basename_dir"
    fi
fi
