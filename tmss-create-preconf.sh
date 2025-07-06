#!/usr/bin/env bash

# Strict usage: ./script.sh <session_name> -f <dir> [options in order]
ses_name="$1"
shift

if [[ -z "$ses_name" || "$1" != "-f" || -z "$2" ]]; then
    echo "Usage: $0 <session_name> -f <dir> [options...]"
    exit 1
fi

dir="$(realpath -m "$2")"; dir="${dir%/}"
shift 2

# File setup
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TMSS_CONFIG_DIR="$CONFIG_HOME/tmss"
mkdir -p "$TMSS_CONFIG_DIR/preconf-sessions"
PRECONF_FILE="${TMSS_CONFIG_DIR}/preconf-sessions/${ses_name}.sh"
LIST_FILE="${TMSS_CONFIG_DIR}/tmss-preconf-list.sh"

# Init script
{
echo '#!/usr/bin/env bash'
echo
echo "# Setup window 1"
echo "tmux send-keys -t \"\${SESSION}:1.1\" \"cd \${DIR}\" C-m"
echo "tmux send-keys -t \"\${SESSION}:1.1\" \"clear\" C-m"
} > "$PRECONF_FILE"

# Trackers
win_num=1
pane_num=1

# Process flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c)
            shift
            [[ -z "$1" ]] && echo "Missing argument for -c" && exit 1
            cmd="${1//\"/\\\"}"  # Escape quotes
            echo "tmux send-keys -t \"\${SESSION}:${win_num}.${pane_num}\" \"$cmd\" C-m" >> "$PRECONF_FILE"
            ;;
        -w)
            win_num=$((win_num + 1))
            pane_num=1
            printf "\n# Add new window %s\n" "$win_num" >> "$PRECONF_FILE"
            echo "tmux new-window -t \"\${SESSION}:${win_num}\"" >> "$PRECONF_FILE"
            ;;
        --hp)
            echo "tmux split-window -h -t \"\${SESSION}:${win_num}.${pane_num}\"" >> "$PRECONF_FILE"
            pane_num=$((pane_num + 1))
            ;;
        --vp)
            echo "tmux split-window -v -t \"\${SESSION}:${win_num}.${pane_num}\"" >> "$PRECONF_FILE"
            pane_num=$((pane_num + 1))
            ;;
        --hps)
            shift
            [[ -z "$1" ]] && echo "Missing argument for --hps" && exit 1
            echo "tmux split-window -h -p $1 -t \"\${SESSION}:${win_num}.${pane_num}\"" >> "$PRECONF_FILE"
            pane_num=$((pane_num + 1))
            ;;
        --vps)
            shift
            [[ -z "$1" ]] && echo "Missing argument for --vps" && exit 1
            echo "tmux split-window -v -p $1 -t \"\${SESSION}:${win_num}.${pane_num}\"" >> "$PRECONF_FILE"
            pane_num=$((pane_num + 1))
            ;;
        *)
            echo "Unknown flag or argument: $1"
            exit 1
            ;;
    esac
    shift
done

# Final select
printf "\n# Select initial window\n" >> "$PRECONF_FILE"
echo "tmux select-window -t \"\${SESSION}:1\"" >> "$PRECONF_FILE"

chmod +x "$PRECONF_FILE"
echo "Preconfiguration script created at: $PRECONF_FILE"

# Update list
echo "preconf_sessions[\"$dir\"]=\"$ses_name\"" >> "$LIST_FILE"
echo "Added to $LIST_FILE: $dir → $ses_name"
