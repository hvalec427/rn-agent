#!/bin/sh
# Remove the rn-agent Claude Code plugin; with --tools, also signalbox, simon
# and boop.
#
#   gh api repos/hvalec427/rn-agent/contents/uninstall.sh -H "Accept: application/vnd.github.raw" | sh
#   … | sh -s -- --tools
set -e

if command -v claude >/dev/null 2>&1; then
  claude plugin uninstall rn-agent@rn-agent 2>/dev/null || true
  claude plugin marketplace remove rn-agent 2>/dev/null || true
  echo "Removed the rn-agent plugin."
fi

if [ "$1" = "--tools" ]; then
  for tool in signalbox simon boop; do
    echo "── $tool"
    curl -fsSL "https://raw.githubusercontent.com/hvalec427/$tool/develop/uninstall.sh" | sh
  done
else
  echo "signalbox, simon and boop stay installed (… | sh -s -- --tools removes them too)."
fi
