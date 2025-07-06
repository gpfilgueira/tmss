#!/usr/bin/env bash
set -e

# Figure out where this script (install.sh) lives
INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Ensure ~/bin exists
BIN_DIR="$HOME/bin"
mkdir -p "$BIN_DIR"

# Write the tmss launcher script
cat > "$BIN_DIR/tmss" <<EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/tmss.sh" "\$@"
EOF

# Make sure it's executable
chmod +x "$BIN_DIR/tmss"

echo "Installed tmss launcher to $BIN_DIR/tmss"
echo "It will always run the tmss.sh located at:"
echo "  $INSTALL_DIR/tmss.sh"
echo
echo "Try running: tmss -h"

