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

```sh
curl -fsSL https://raw.githubusercontent.com/hvalec427/rn-agent/master/install.sh | sh
```

It installs the three tools (each into `~/.<tool>/bin`, no sudo) and the
plugin into Claude Code. Run it again to update everything. The tools come
from their dev builds, which have what agents need (`signalbox up --detach`);
pick another channel with `… | sh -s -- stable` (or `nightly`, or a version
tag). Open a new terminal afterwards, so the tools are on your PATH.

It also needs (the installer says what's missing):

- macOS with Xcode selected: `sudo xcode-select -s /Applications/Xcode.app`
- tmux: `brew install tmux`
- GitHub's CLI, logged in (`gh auth login`), for opening pull requests

Only the plugin, from inside Claude Code:

```
/plugin marketplace add hvalec427/rn-agent
/plugin install rn-agent@rn-agent
```

Register each app once, in its main checkout: `signalbox init` (it asks for
a name; skip it if signalbox already knows the app).

Uninstall: the same command with `uninstall.sh` removes the plugin; add
`sh -s -- --tools` to remove the tools too. It adds nothing to your repos.

## Using it

1. `claude --worktree price-screen`: a task in a worktree and branch of its own.
2. Ask questions (answered from the code) and for changes: the agent starts the
   app on its own simulator, checks each change there and reports what it saw.
3. Say **finish** (or "open a PR"): it commits, pushes, opens the pull request,
   stops the app (its simulator is deleted) and removes the worktree. The
   branch stays until the PR is merged.
4. Exit Claude.

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
- **Finish:** the `finish` skill commits, pushes and opens the pull request
  (what changed, how it was verified), then stops the app and removes the
  worktree, keeping the branch.
- **Session end:** if the app is still running, it stops and its simulator is
  deleted. A signalbox dashboard you started yourself is left alone.

## Layout

- `plugin/`: the plugin: `hooks/` (session start and end), `skills/run-app/`,
  `skills/finish/`,
  `.mcp.json` (signalbox's MCP server).
- `.claude-plugin/marketplace.json`: this repo as a plugin marketplace.
- `install.sh`, `uninstall.sh`.
