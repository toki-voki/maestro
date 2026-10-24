---
name: commit
description: Create a git commit in maestro — run the project checks, stage only the related files, write a single-line Conventional Commits subject with a scope, no body, no AI trailer. Use when the user says "commit", "commit this", "commit the changes", "amend", or asks to commit/push work in this repo.
---

# commit

Commit rules for maestro. Enforced locally by `.githooks/commit-msg` (enable
once per clone with `make hooks`) and in CI by the `commits` job, both through
`scripts/check-commit-msg.sh`. What the script rejects, this skill forbids.

## When

"commit" authorizes exactly **one** commit: the work it refers to. It does not
carry over to the next slice or fix. After finishing a change, leave it in the
working tree, report, and wait for the next "commit". Same for `--amend`:
amend only when told, and only the last commit, never a pushed one.

## Message

```
type(scope): summary
```

- **type**: one of `feat` `fix` `docs` `style` `refactor` `perf` `test`
  `build` `ci` `chore` `revert`.
- **scope**: required, lowercase, the module or domain the change lives in:
  `server`, `client`, `cli`, `tools`, `release`, `distribution`, `repo`, `prd`,
  … Derive it from the changed files. `!` after the scope marks a breaking
  change (`feat(cli)!: …`).
- **summary**: imperative, states what actually changed, not how or why. Two
  related concerns join with `;`.
- **Subject line only, no body.** Max 150 characters. If it needs a body to be
  understood, split it into several commits. Rationale goes in code comments or
  docs; release notes go in `CHANGELOG.md`.
- **No AI trailer.** Never `Co-Authored-By: Claude …` or any
  "Generated with …" footer. Same for PR descriptions.

Examples:

```
feat(server): add unix socket hub
fix(cli): exit non-zero when the server is unreachable; print socket path
build(tools): pin dev tools in .bin/ keyed by version and Go
docs(release): add v0.1.0 changelog
```

## Procedure

1. `git status --short` and `git diff` — know exactly what changed.
2. If the change is user-visible, make sure it has a line under
   `## [Unreleased]` in `CHANGELOG.md` (Keep a Changelog format). Add one in
   the same commit if missing.
3. `make check` must be green (fmt-check, lint, lint-windows, govulncheck,
   osv-check, race tests). Red → report and stop, do not commit over it.
   Docs-only or config-only changes may skip it; say so.
4. Stage **only the related files** with `git add <paths>`. Never `git add -A`.
   One logical change per commit; unrelated edits stay in the working tree.
5. `git commit -m "type(scope): summary"`. If the hook rejects, fix the subject,
   do not bypass with `--no-verify`.
6. Show `git log --oneline -1` and the remaining `git status --short`.

## Pushing

Only on an explicit ask. Push the current feature branch, never `main`
(protected, PR required). First push: `git push -u origin <branch>`.
