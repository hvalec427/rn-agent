#!/bin/sh
# Install rn-agent: signalbox, simon and boop (each from its own releases, into
# ~/.<tool>/bin, no sudo) and the rn-agent Claude Code plugin.
#
#   curl -fsSL https://raw.githubusercontent.com/hvalec427/rn-agent/main/install.sh | sh
#   … | sh -s -- nightly     the tools' channel: dev (default), nightly, or a version tag
#
# Run it again to update everything.
set -e

CHANNEL="${1:-dev}"
TOOLS="signalbox simon boop"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "rn-agent needs macOS (iOS simulators)." >&2
  exit 1
fi

for tool in $TOOLS; do
  echo "── $tool"
  curl -fsSL "https://raw.githubusercontent.com/hvalec427/$tool/develop/install.sh" | sh -s -- "$CHANNEL"
done

echo "── Claude Code plugin"
if command -v claude >/dev/null 2>&1; then
  # The first run adds and installs it; later runs update it.
  claude plugin marketplace add hvalec427/rn-agent >/dev/null 2>&1 || claude plugin marketplace update rn-agent
  claude plugin install rn-agent@rn-agent
  claude plugin update rn-agent@rn-agent >/dev/null 2>&1 || true
else
  echo "Claude Code isn't installed: install it, then run this again (or in Claude Code:"
  echo "  /plugin marketplace add hvalec427/rn-agent  and  /plugin install rn-agent@rn-agent)."
fi

echo "──"
command -v tmux >/dev/null 2>&1 || echo "Also needed: tmux (brew install tmux); agents run the app in it."
xcrun simctl help >/dev/null 2>&1 || echo "Also needed: Xcode selected for simulators (sudo xcode-select -s /Applications/Xcode.app)."
echo "Done. Register each app once: signalbox init in its main checkout."
echo "Then start a task with: claude --worktree <name>   (open a new terminal first if a tool isn't found)"
