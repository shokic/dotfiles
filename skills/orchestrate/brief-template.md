# Brief: <worker name>

<!-- The worker starts with no context: it has not seen the conversation, the plan, or the
other workers. Everything it needs is in this file or in a file this file points to.
Delete these comments and any section that doesn't apply. -->

## Objective

<!-- What to achieve and why it matters, in two or three sentences. State the outcome,
not the steps: the worker chooses how. -->

## Context

<!-- What you already know that saves the worker from rediscovering it: the files and
functions involved (with paths), the decision you made and the alternatives you ruled out,
the docs to read first (the repo's conventions for this kind of change). Point to files
instead of pasting them. -->

## Boundaries

- Work only in this worktree, on the branch it's on.
- In scope: <!-- files or areas this worker owns -->
- Out of scope: <!-- what other workers own, or what must not change (public API, schema…) -->
- Don't push, open a PR, or touch anything outside the repository.

## Setup

<!-- A fresh worktree has no installed dependencies and no build output. Give the commands
this repo needs before anything runs, from its docs. -->

## Done means

<!-- Checks the worker can run itself, as commands with the expected result. Without
them it stops when the code looks right, not when it works. -->

- [ ] <!-- e.g. the new test passes: `yarn test path/to/file.spec.ts` -->
- [ ] <!-- lint and typecheck pass on the touched packages -->
- [ ] The work is committed on this branch, following the repo's commit conventions.

## If you're stuck

Don't guess on a decision that changes the design or goes beyond the boundaries. Write
the report with status `blocked`, say what you need decided and the options you see,
then stop. A blocked report is a good outcome; a wrong guess isn't.

## Report

When you finish or are blocked, write `<absolute path>/.claude/orchestrator/<worker name>.report.md`,
under 40 lines, then stop:

- **Status:** done | blocked | failed
- **What changed:** the files, and one line each on why
- **Commits:** hashes and subjects
- **Checks:** each command you ran and its real result, including failures
- **Not done or uncertain:** anything skipped, assumed, or worth a second look
- **Decisions needed:** only if blocked
