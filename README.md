# rn-agent

Claude Code agents for React Native apps. Each Claude Code session in an app's
checkout gets its own iOS simulator and Metro port, started when the agent
needs the app and never shared with another session, so several agents can
work on different tasks side by side.

It's a Claude Code plugin on top of three tools, each in its own repo:

- [signalbox](https://github.com/hvalec427/signalbox): Metro, builds,
  simulators and sessions; hands out ports and simulators so no two sessions
  share one. Agents use it through `signalbox mcp`.
- [boop](https://github.com/hvalec427/boop): the app's screen: screenshots,
  the element tree, taps, typing, deep links.
- [simon](https://github.com/hvalec427/simon): simulators and emulators from
  the command line (signalbox is built on it).

## Install

The repo is private for now, so install through GitHub's CLI (logged in with
`gh auth login`):

```sh
gh api repos/hvalec427/rn-agent/contents/install.sh -H "Accept: application/vnd.github.raw" | sh
```

It installs the three tools (each into `~/.<tool>/bin`, no sudo) and the
plugin into Claude Code. Run it again to update everything. The tools come
from their dev builds, which have what agents need (`signalbox up --detach`);
pick another channel with `… | sh -s -- stable` (or `nightly`, or a version
tag). It needs macOS, Xcode (selected with `xcode-select`) and tmux.

Only the plugin, from inside Claude Code:

```
/plugin marketplace add hvalec427/rn-agent
/plugin install rn-agent@rn-agent
```

Register each app once, in its main checkout: `signalbox init`.

Uninstall: the same command with `uninstall.sh` removes the plugin; add
`sh -s -- --tools` to remove the tools too. It adds nothing to your repos.

## Using it

There's nothing to call: start Claude Code in an app's checkout and work as
usual. Ask a question and the agent answers from the code; ask for a change and
it starts the app on its own simulator, checks the change there and reports
what it saw. To start the app yourself first, type `/rn-agent:run-app`.

## How it works

Start each task in a worktree of its own:

```sh
claude --worktree price-screen
```

- **Session start:** in a React Native checkout, the plugin points boop at
  that checkout's signalbox session, clones `node_modules`, `ios/Pods` and
  `.env*` from the main checkout into a new worktree (APFS clones: instant),
  and tells the agent whether the app is running. Elsewhere it does nothing.
- **Questions** are answered from the code; nothing starts.
- **Changes:** before checking something in the app, the `run-app` skill has
  the agent run `signalbox up --detach --port auto --new-sim --prebuilt` (a
  port and a simulator of its own, the app installed from the main checkout's
  last build), wait for it with signalbox's `wait_ready`, look with boop, and
  read errors and logs through signalbox's tools.
- **Session end:** the app it started stops and its simulator is deleted. A
  signalbox dashboard you started yourself is left alone.

Watch what agents run with `tmux -L signalbox attach` (a window per checkout).

## Layout

- `plugin/`: the plugin: `hooks/` (session start and end), `skills/run-app/`,
  `.mcp.json` (signalbox's MCP server).
- `.claude-plugin/marketplace.json`: this repo as a plugin marketplace.
- `install.sh`, `uninstall.sh`.
