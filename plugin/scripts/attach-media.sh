#!/bin/sh
# Upload screenshots and recordings for this branch's pull request and print the
# markdown that shows them.
#
#   attach-media.sh <file>...
#
# GitHub has no CLI for PR attachments, so the files go to a branch of their
# own in the same repo, rn-agent-media (no shared history with the code), under
# a folder named after this branch; anyone who can see the repo sees them.
set -e

[ $# -gt 0 ] || { echo "usage: attach-media.sh <file>..." >&2; exit 2; }
MEDIA=rn-agent-media
# owner/repo from origin (git@github.com:o/r.git or https://github.com/o/r).
repo=$(git remote get-url origin | sed -E 's#^.*github\.com[:/]##; s#\.git$##')
branch=$(git rev-parse --abbrev-ref HEAD | tr '/' '-')
dir="$branch/$(date +%Y%m%d-%H%M%S)"

tries=0
while :; do
  git fetch -q origin "$MEDIA" 2>/dev/null || true
  base=$(git rev-parse -q --verify "refs/remotes/origin/$MEDIA" || true)
  index=$(mktemp)
  rm -f "$index"
  if [ -n "$base" ]; then GIT_INDEX_FILE=$index git read-tree "$base"; fi
  for f in "$@"; do
    blob=$(git hash-object -w "$f")
    GIT_INDEX_FILE=$index git update-index --add --cacheinfo "100644,$blob,$dir/$(basename "$f")"
  done
  tree=$(GIT_INDEX_FILE=$index git write-tree)
  rm -f "$index"
  if [ -n "$base" ]; then
    commit=$(git commit-tree "$tree" -p "$base" -m "Media for $branch")
  else
    commit=$(git commit-tree "$tree" -m "Media for rn-agent pull requests")
  fi
  # Another session may have pushed meanwhile: fetch and try again.
  if git push -q origin "$commit:refs/heads/$MEDIA" 2>/dev/null; then break; fi
  tries=$((tries + 1))
  [ $tries -lt 3 ] || { echo "couldn't push to $MEDIA" >&2; exit 1; }
done

for f in "$@"; do
  name=$(basename "$f")
  url="https://github.com/$repo/blob/$MEDIA/$dir/$name?raw=true"
  case "$name" in
  *.png | *.jpg | *.jpeg | *.gif) echo "![${name%.*}]($url)" ;;
  *) echo "[$name]($url)" ;;
  esac
done
