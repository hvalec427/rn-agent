---
name: finish
description: Finish this task: commit, push, open a pull request, then stop the app and remove this worktree (the branch stays). Use when the user says finish, ship it, or asks for a PR for the work in a `claude --worktree` session.
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git add *) Bash(git commit *) Bash(git push *) Bash(git rev-parse *) Bash(git worktree *) Bash(gh pr *) Bash(gh repo view *) Bash(signalbox *)
---

# Finish

Ship the work in this worktree as a pull request, then clear the worktree away. Each step
ends on its own check; stop and tell the user at the first one that fails, leaving
everything in place.

1. **Ready.** The change was seen working (run-app's "done means seen"), or what couldn't
   be verified is known, to go in the description. Done when you can say which.
2. **Commit.** `git status` shows what's left: commit it in the repo's style and the
   user's commit conventions. `.signalbox/` is git-excluded and stays out. Done when
   `git status --porcelain` prints nothing.
3. **Push.** `git push -u origin HEAD`. Done when it succeeds.
4. **Pull request.** `gh pr create` against the repo's default branch
   (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`), following the user's
   PR conventions. The title says the change; the body says what changed and how it was
   verified (screens seen, checks run), and names anything left open. An existing PR for
   this branch (`gh pr view`) is updated by the push instead. Done when you have its URL.
5. **Clean up.** Stop the app this session started: `signalbox down --detached-only`, which
   deletes its simulator. Then remove the worktree from the main checkout, keeping the
   branch: `git -C <main checkout> worktree remove <this worktree>`, where the main
   checkout is `git rev-parse --path-format=absolute --git-common-dir` without its trailing
   `/.git`. Done when `git -C <main checkout> worktree list` no longer lists it.
6. **Hand back.** Tell the user, in a few lines: the PR's URL, that the worktree is gone and
   the branch stays until the PR is merged, and that this session is finished, so they can
   exit it.
