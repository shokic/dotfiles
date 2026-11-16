# Brief: <worker name>

<!-- The worker starts with no context: it has not seen the conversation, the plan, or the
other workers. Everything it needs is in this file or in a file this file points to.
Delete these comments and any section that doesn't apply. -->

## Objective

<!-- What to achieve and why it matters, in two or three sentences. State the outcome,
not the steps: the worker chooses how. Quote the user's own words for the decisions they
made, so the worker doesn't reopen them. -->

## Context

<!-- What you already know that saves the worker from rediscovering it: the files and
functions involved (with paths), the decision you made and the alternatives you ruled out,
the docs to read first (the repo's conventions for this kind of change). Point to files
instead of pasting them. Say what the branch is based on and what sits above or below it
when branches are stacked. -->

## Boundaries

- Work only in this worktree, on the branch it's on.
- In scope: <!-- files or areas this worker owns -->
- Out of scope: <!-- what other workers own, or what must not change (public API, schema…) -->
- Don't push, open a PR, or touch anything outside the repository.
- Nothing you run may reach production, a real third party or a real person. If a step
  would, stop and report it as a decision for the user.
- Don't work around a permission prompt: wait for the user to answer it.
- This worktree shares its `.git` with the user's checkout and the other workers. Don't
  write shared state there (git hooks, git config, stashes): run installs that would in
  a scratch clone, or with the tool's "CI" switch.
<!-- Add the repo's own hard rules here, quoted (for example what its AGENTS.md forbids). -->

## Setup

<!-- A fresh worktree has no installed dependencies and no build output. Give the commands
this repo needs before anything runs, from its docs. Mention what misbehaves in a worktree
nested inside the main checkout (tools that look upward for the workspace root). -->

## Done means

<!-- Checks the worker can run itself, as commands with the expected result. Without
them it stops when the code looks right, not when it works. -->

- [ ] <!-- e.g. the new test passes: `yarn test path/to/file.spec.ts` -->
- [ ] The repo's checks pass **the way CI runs them**, for everything the change affects,
      not only the files touched: <!-- the CI command, e.g. `yarn turbo ci --filter=[origin/main]` -->
- [ ] <!-- for a tool or a check: a deliberate violation is caught, then reverted -->
- [ ] The work is committed on this branch, following the repo's commit conventions, one
      purpose per commit. No `Co-Authored-By` line or any other AI attribution.
- [ ] Few code comments: only what a future reader can't get from the code (why an
      exception exists, a trap). None that restate the code or narrate the change.

## If you're stuck

Don't guess on a decision that changes the design or goes beyond the boundaries. Write
the report with status `blocked`, say what you need decided and the options you see,
then stop. A blocked report is a good outcome; a wrong guess isn't.

## Report

When you finish or are blocked, write `<absolute path>/.claude/orchestrator/<worker name>.report.md`,
then stop. For a follow-up, append a section named after it instead of rewriting the file.

- **Status:** done | blocked | failed
- **What changed:** the files, and one line each on why
- **Commits:** hashes and subjects
- **Checks:** each command you ran and its real result, including failures and what you
  could not run
- **Decisions for the user:** choices you made that they might have made differently,
  and anything that needs their answer
- **Not done or uncertain:** anything skipped, assumed, or worth a second look
<!-- When the work changes how people use the repo, also ask for "What changes for
developers", in plain words: it becomes the announcement. -->

No placeholder may be left in the report: a section you can't fill says why.
