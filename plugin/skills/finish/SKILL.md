---
name: finish
description: Finish this task: commit, push, open a pull request with screenshots and a recording of the change attached, then stop the app and remove this worktree (the branch stays). Use when the user says finish, ship it, or asks for a PR for the work in a `claude --worktree` session.
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git add *) Bash(git commit *) Bash(git push *) Bash(git rev-parse *) Bash(git worktree *) Bash(gh pr *) Bash(gh repo view *) Bash(signalbox *) Bash(boop *) Bash(cp *) Bash(sh ${CLAUDE_PLUGIN_ROOT}/scripts/*)
user-invocable: false
---

# Finish

Ship the work in this worktree as a pull request, then clear the worktree away. Each step
ends on its own check; stop and tell the user at the first one that fails, leaving
everything in place.

1. **Ready.** The change was seen working (run-app's "done means seen"), or what couldn't
   be verified is known, to go in the description. Done when you can say which.
2. **Show it.** While the app is still running, capture what a reviewer needs to see the
   change without running it:
   - every screen the change touched, in its final state: `boop screenshot` prints a JPEG
     path; copy it to `.signalbox/media/<what-it-shows>.jpg` in this checkout;
   - for a change you interact with (a flow, an animation, a form): a recording of you
     walking it. `sh ${CLAUDE_PLUGIN_ROOT}/scripts/record.sh start`, walk the flow with boop
     at a pace a viewer can follow, then `sh ${CLAUDE_PLUGIN_ROOT}/scripts/record.sh stop
     <what-it-shows>`, which prints the recording's path. Keep it short (well under a
     minute): the one flow the change is about.

   Changes with nothing to see (logic, tooling, tests) skip this step. Done when each
   changed screen and flow has its file, or there's nothing to show.
3. **Commit.** `git status` shows what's left: commit it in the repo's style and the
   user's commit conventions. `.signalbox/` (the media included) is git-excluded and stays
   out. Done when `git status --porcelain` prints nothing.
4. **Push.** `git push -u origin HEAD`. Done when it succeeds.
5. **Pull request.** `gh pr create` against the repo's default branch
   (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`), following the user's
   PR conventions. The title says the change; the body says what changed and how it was
   verified (screens seen, checks run), and names anything left open. Place each media
   file where it belongs in the body by its local path (`![Price list](.signalbox/media/price-list.jpg)`)
   and pass every file with `--attach <path>`: gh uploads them and swaps in their URLs, so
   they show inline (videos play). An existing PR for this branch (`gh pr view`) gets the
   push, and the new media through `gh pr edit --body … --attach …`. Needs gh 2.99 or newer:
   with an older one, open the PR without the media and tell the user to `brew upgrade gh`.
   Done when you have its URL.
6. **Clean up.** Stop the app this session started: `signalbox down --detached-only`, which
   deletes its simulator. Then remove the worktree from the main checkout, keeping the
   branch: `git -C <main checkout> worktree remove --force <this worktree>` (`--force` for
   the git-excluded `.signalbox/`), where the main checkout is
   `git rev-parse --path-format=absolute --git-common-dir` without its trailing `/.git`.
   Done when `git -C <main checkout> worktree list` no longer lists it.
7. **Hand back.** Tell the user, in a few lines: the PR's URL, that the worktree is gone and
   the branch stays until the PR is merged, and that this session is finished, so they can
   exit it.
