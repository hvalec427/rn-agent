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
- ffmpeg (`brew install ffmpeg`), optional: turns recordings into GIFs that
  play inside the PR

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
3. Say **finish** (or "open a PR"): it commits, pushes and opens the pull
   request, with screenshots of the changed screens and a short recording of
   the flow, so you can review it without running the app. Then it stops the
   app (its simulator is deleted) and removes the worktree. The branch stays
   until the PR is merged.
4. Exit Claude.

## Bigger features, with Matt Pocock's skills

rn-agent works alongside [Matt Pocock's skills](https://github.com/mattpocock/skills):
they plan and build the code, rn-agent gives each session an app of its own to
check it in. For a feature too big for one go:

**Plan**, in a normal session in the main checkout:

1. `/grill-with-docs` interviews you until the feature is clear, writing the
   app's domain docs as it goes (`GLOSSARY.md`, decision records in `docs/adr/`).
2. `/to-spec` turns that into the **spec**: the whole feature, once: the
   problem, the solution, user stories, the implementation and testing
   decisions. It says *what* to build and *why*.
3. `/to-tickets` splits the spec into **tickets**: thin end-to-end slices, each
   small enough for one agent session and checkable on its own, each listing the
   tickets that block it. They say *in what pieces, and in what order*.

For example, spec #123 "Price screen redesign" becomes tickets #124 "Show prices
per item" (blocked by nothing), #125 "Discount badges" and #126 "Price breakdown
sheet" (both blocked by #124).

Specs and tickets go to the issue tracker `/setup-matt-pocock-skills` set up,
once per repo: GitHub Issues (one issue each), or markdown files under
`.scratch/<feature>/`. The setup and the domain docs add files to the repo; in
a shared repo, pick local markdown (and keep `.scratch/` out of git) to keep it
to yourself.

**Build**, one feature per worktree and one pull request per feature; separate
features can run side by side, each with its own simulator:

```sh
claude -w price-redesign
```

then the tickets in order, each building on the last:

```
/implement ticket 124
/implement ticket 125
/implement ticket 126
finish
```

When a session gets long, `/handoff`, exit, and carry on in a new session in the
same worktree (`cd .claude/worktrees/price-redesign && claude`).

`/implement-spec #123` does this on its own: it follows the blocking order,
builds independent tickets at the same time in subagents (each in a worktree of
its own) and ends with a code review. rn-agent doesn't support those subagent
worktrees yet (they get no `node_modules`, and an app a subagent starts isn't
stopped when it's done), so build ticket by ticket for now.

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
- **Finish:** the `finish` skill screenshots the changed screens and records
  the flow (a GIF, which plays inline, when ffmpeg is installed), commits,
  pushes and opens the pull request (what changed, how it was verified, the
  media), then stops the app and removes the worktree, keeping the branch.
  GitHub has no CLI for PR attachments, so the media goes to a branch of its
  own in the repo, `rn-agent-media`, which shares no history with the code.
- **Session end:** if the app is still running, it stops and its simulator is
  deleted. A signalbox dashboard you started yourself is left alone.

## Layout

- `plugin/`: the plugin: `hooks/` (session start and end), `skills/run-app/`,
  `skills/finish/`,
  `.mcp.json` (signalbox's MCP server).
- `.claude-plugin/marketplace.json`: this repo as a plugin marketplace.
- `install.sh`, `uninstall.sh`.
