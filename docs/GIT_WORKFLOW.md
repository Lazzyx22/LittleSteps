# LittleSteps Git workflow

This folder is already a local Git repository. Do not run `git init` again.
No remote is configured and nothing has been pushed to GitHub.

## Branches in this repository

| Branch | Purpose |
| --- | --- |
| `main` | Verified MVP release. Start here to run the stable starter. |
| `develop` | Integration branch for the next release. |
| `feature/foundation` | Flutter launchers, models, repositories, theme, original JSON content. |
| `feature/child-learning` | Profile UI, subject navigation, lesson/activity engines, progress and parent mode. |
| `feature/quality-and-docs` | Tests, cleanup, original app icons, offline web configuration and documentation. |

Feature branches are kept as a learning example. They record the state of each stage, so use `main` for the final app. New work should start from the latest `develop`, not an old feature branch.

```text
main ── initial repository ─────────────────────── verified release
             ╲                                      ╱
develop ── foundation merge ── learning merge ── quality merge
              ╱                   ╱                  ╱
feature/foundation   feature/child-learning   feature/quality-and-docs
```

## Identity and useful checks

The initial commits use the explicit local-only identity `LittleSteps Local <littlesteps@localhost>` because no email was configured. Set your own identity before future commits. These commands affect only this repository:

```powershell
git config user.name "Your Name"
git config user.email "your-address@example.com"
git status
git branch --show-current
git log --graph --oneline --decorate --all
```

A commit is a named snapshot of staged changes on the current branch. A branch is a movable name pointing to a commit. Switching branches changes the files you see. A merge combines histories; it does not upload anything. A push sends commits to a configured remote.

## Start a task on a branch

```powershell
git status
git switch develop
git switch -c feature/recorded-instructions
```

Use `feature/short-description` for features, `fix/short-description` for fixes, and `docs/short-description` for documentation. One branch should have one clear purpose. Commit or deliberately stash unfinished changes before switching tasks.

## Make a focused commit

Edit files, then review the diff and run checks:

```powershell
dart format lib test
flutter analyze
flutter test --concurrency=1
git diff
git add lib/features/lessons/lesson_runner.dart
git diff --staged
git commit -m "feat: add recorded lesson instructions"
git status
```

Stage the exact files you intend to commit. `git add -p` lets you stage selected portions. `git restore --staged path/to/file` unstages a file while preserving its edits. Avoid committing SDKs, build directories, passwords, signing keys, or local configuration. `.gitignore` already excludes common generated files.

Use messages describing the outcome: `feat: add plant matching activity`, `fix: preserve progress after a failed save`, `test: cover parent route locking`, or `docs: explain lesson authoring`.

If your Flutter SDK is not on PATH on this machine:

```powershell
$env:Path = "C:\Users\lazyg\develop\flutter\bin;" + $env:Path
```

## Merge the task into develop

First commit the feature. Merge the latest integration changes into it and test the combined result:

```powershell
git switch feature/recorded-instructions
git merge develop
flutter analyze
flutter test --concurrency=1
git switch develop
git merge --no-ff feature/recorded-instructions -m "merge: add recorded instructions"
git status
```

`--no-ff` creates an explicit merge commit so the task boundary remains visible. A normal `git merge branch` may simply advance the branch pointer if there is no divergent history. This repository uses explicit feature merge commits for learning clarity.

## Resolve a merge conflict

If Git reports conflicts, stop and inspect `git status`. Open each conflicted file and choose the intended combined behavior. Remove `<<<<<<<`, `=======`, and `>>>>>>>` markers. Keep both sides where appropriate; do not accept an entire side without reading it.

```powershell
git status
# Edit each conflicted file.
git add path/to/resolved_file.dart
flutter analyze
flutter test --concurrency=1
git commit
```

`git commit` finishes the merge after all conflicts are staged. To abandon an in-progress merge, use `git merge --abort`; start merges with a clean working tree so this can safely restore the pre-merge state.

## Release develop to main

```powershell
git switch develop
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --concurrency=1
flutter build web --no-web-resources-cdn --no-wasm-dry-run
git switch main
git merge --no-ff develop -m "release: ship next LittleSteps iteration"
git tag -a v0.2.0 -m "LittleSteps next iteration"
git switch develop
git merge main
```

Use the next unused version tag. The starter release is tagged `v0.1.0`. A tag fixes a release name to one commit; it does not move as a branch does.

After integration, `git branch -d feature/recorded-instructions` safely deletes the local branch name only if its work is merged. Keeping the branches in this starter is intentional. Avoid `-D`, `reset --hard`, and force pushes as routine workflow.

## Undo a published mistake with a new commit

```powershell
git log --oneline
git revert COMMIT_HASH
```

This preserves history and records the correction. Reverting a merge needs a deliberate mainline choice; inspect the merge and ask a teammate before doing that.

## Optional GitHub remote later

Create an empty remote repository without an initial README, then substitute its URL:

```powershell
git remote add origin https://github.com/YOUR_ACCOUNT/LittleSteps.git
git push -u origin main
git push -u origin develop
git push origin v0.1.0
```

For team work, push a feature branch and open a pull request targeting `develop`. Pull requests are reviewed and tested before merging; release PRs target `main`. Use `git fetch origin` followed by `git merge origin/develop` on your feature branch to bring in teammates' changes. Set branch protection and required checks in the hosting service when collaboration begins.

## Windows ownership note

The automated environment used two Windows accounts. If Git reports **dubious ownership** and you recognize this exact project, a command-scoped exception is:

```powershell
git -c safe.directory=C:/Project/LittleSteps status
```

You can insert `-c safe.directory=C:/Project/LittleSteps` after `git` in other commands too. Do not trust all directories with a wildcard. Normal work under the same Windows account that owns the repository should not require this exception.
