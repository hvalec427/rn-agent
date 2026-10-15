#!/bin/sh
# Record this checkout's simulator (the device in .signalbox/session.json).
#
#   record.sh start          start recording in the background
#   record.sh stop [name]    stop; prints the recording: a GIF (plays inline in
#                            a PR) when ffmpeg is installed, else the .mp4
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
  if command -v ffmpeg >/dev/null 2>&1; then
    gif="$media/$name.gif"
    # Small and short enough for a PR: 10 fps, 320 px wide, one palette.
    ffmpeg -nostdin -loglevel error -y -i "$mp4" \
      -vf "fps=10,scale=320:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" \
      -loop 0 "$gif" && echo "$gif" && exit 0
  fi
  echo "$mp4"
  ;;
*)
  echo "usage: record.sh start | stop [name]" >&2
  exit 2
  ;;
esac
