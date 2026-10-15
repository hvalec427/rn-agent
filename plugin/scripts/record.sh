#!/bin/sh
# Record this checkout's simulator (the device in .signalbox/session.json).
#
#   record.sh start          start recording in the background
#   record.sh stop [name]    stop; prints the recording (.mp4, which plays inline
#                            when attached to a PR)
#
# Files go to .signalbox/media/, which git ignores and which goes away with the
# worktree.
set -e

root=$(git rev-parse --show-toplevel)
media="$root/.signalbox/media"
pidfile="$media/recording.pid"

case "$1" in
start)
  udid=$(sed -n 's/.*"udid": *"\([^"]*\)".*/\1/p' "$root/.signalbox/session.json" 2>/dev/null) || true
  [ -n "$udid" ] || { echo "this checkout's app isn't running: start it first" >&2; exit 1; }
  mkdir -p "$media"
  if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
    echo "already recording; stop it first" >&2
    exit 1
  fi
  out="$media/recording.mp4"
  rm -f "$out"
  nohup xcrun simctl io "$udid" recordVideo --codec=h264 --force "$out" >"$media/recording.log" 2>&1 &
  echo $! >"$pidfile"
  sleep 1
  kill -0 "$(cat "$pidfile")" 2>/dev/null || { cat "$media/recording.log" >&2; exit 1; }
  echo "recording; walk the flow, then: record.sh stop <name>"
  ;;
stop)
  name="${2:-flow}"
  [ -f "$pidfile" ] || { echo "not recording" >&2; exit 1; }
  pid=$(cat "$pidfile")
  # SIGINT lets simctl finish the file.
  kill -INT "$pid" 2>/dev/null || true
  i=0
  while kill -0 "$pid" 2>/dev/null && [ $i -lt 100 ]; do sleep 0.1; i=$((i + 1)); done
  rm -f "$pidfile"
  mp4="$media/$name.mp4"
  mv "$media/recording.mp4" "$mp4"
  echo "$mp4"
  ;;
*)
  echo "usage: record.sh start | stop [name]" >&2
  exit 2
  ;;
esac
