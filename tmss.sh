#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
TMSS_STATE_DIR="$STATE_HOME/tmss"
SPEAR_FILE="$TMSS_STATE_DIR/spear-sessions.txt"

cmd="${1:-find}"
shift || true

case "$cmd" in
    create-preconf)
        bash "$SCRIPT_DIR/tmss-create-preconf.sh" "$@"
        ;;
    -f|fd|find|"")
        bash "$SCRIPT_DIR/tmss-fd.sh" "$@"
        ;;
    -s|spear)
        bash "$SCRIPT_DIR/tmss-spear.sh" "$@"
        ;;
    -m|manage)
        bash "$SCRIPT_DIR/tmss-manage.sh" "$@"
        ;;
    -e)
        "${EDITOR:-vi}" "$SPEAR_FILE"
        ;;
    *)
        echo "Usage:"
        echo "  tmss                # default = find"
        echo "  tmss -f | fd | find # run finder"
        echo "  tmss -s | spear     # jump to session"
        echo "  tmss -m | manage    # manage sessions"
        echo "  tmss create-preconf # create preconfiguration"
        echo "  tmss -e             # edit spear file"
        exit 1
        ;;
esac
