# Release procedure

Release procedure for maestro. Versions are git tags in `vMAJOR.MINOR.PATCH`
form (e.g. `v0.2.0`), annotated, pointing at the commit on `main` that adds
the CHANGELOG entry. Release notes live in `CHANGELOG.md` (Keep a Changelog
format).

Pushing the tag triggers `.github/workflows/release.yml`: lint, tests,
GoReleaser (binaries, archives, checksums, deb/rpm/apk, Homebrew cask), with
the GitHub release body taken from `scripts/changelog-section.sh <tag>` — the
exact section the user approved. Stable tags also get a `latest.json` asset,
which `install.sh` fetches through `releases/latest/download/`, i.e. from
whichever release carries GitHub's "Latest" flag; to roll the installer back
to an older release run `gh release edit vX.Y.Z --latest`. `main` is protected
(PR required, no bypass), so the changelog commit lands through a PR; only the
tag is pushed directly, and the workflow never writes to `main`.

Two hard stops: **the checks must pass** before anything is written, and
**the user must approve the CHANGELOG entry** before anything is committed,
tagged or pushed.

## Steps

1. **Preflight**
   ```bash
   git status --short                    # must be clean
   git branch --show-current             # must be main
   git fetch origin && git status -sb    # must not be behind origin/main
   ```
   Stop and report if any fails.

2. **Find the current version**
   ```bash
   git describe --tags --abbrev=0        # e.g. v0.1.0; none yet → first release
   git tag --sort=-v:refname | head
   git merge-base --is-ancestor <prev-tag> HEAD   # releasing forward
   ```

3. **Run the checks — before writing anything.** A failure after tagging
   burns a version number.
   ```bash
   make check             # format check, golangci-lint, govulncheck, race tests
   make tidy              # go.mod/go.sum must already be tidy
   make release-check     # .goreleaser.yaml is valid
   make release-snapshot  # full release build into dist/, publishes nothing
   make check-commits BASE=<prev-tag>   # every subject since the last release passes the commit rules
   ```
   (first release: `make check-commits BASE=$(git rev-list --max-parents=0 HEAD)`)
   `govulncheck` also scans the standard library of the local Go toolchain; if
   it flags stdlib CVEs fixed upstream, upgrade Go to the version pinned in
   `go.mod` rather than skipping. If `fmt-check` fails, run `make fmt`. Report
   anything red to the user and stop — fixes land as their own commits (only
   when the user says "commit"), then restart from step 1.

4. **Gather the changes** since the last tag:
   ```bash
   git log <prev-tag>..HEAD --format='%h %s'     # first release: git log --format='%h %s'
   ```
   Also read the existing `## [Unreleased]` section of `CHANGELOG.md`.

5. **Pick the next version** (SemVer; while `0.x`, breaking changes bump
   MINOR):
   - `feat` commits or user-visible additions → minor (`v0.1.0` → `v0.2.0`)
   - only `fix`/`perf` → patch (`v0.1.0` → `v0.1.1`)
   - any `!` / breaking protocol or CLI change → minor while `0.x`, major after `1.0`
   - `docs`/`ci`/`chore`/`test`/`refactor` alone do not justify a release.

6. **Draft the CHANGELOG entry** in `CHANGELOG.md`:
   - Rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` (today) and add a
     fresh empty `## [Unreleased]` above it.
   - Merge in anything from the commit log missing from Unreleased. Group under
     `### Added`, `### Changed`, `### Deprecated`, `### Removed`, `### Fixed`,
     `### Security` (omit empty groups); breaking changes go first, prefixed
     `**Breaking:**`.
   - Write for users of maestro: what changed for them, one line each. Do not
     paste commit subjects; drop pure ci/chore/refactor noise.
   - Update the link references at the bottom:
     `[Unreleased]: https://github.com/toki-voki/maestro/compare/vX.Y.Z...HEAD`
     and `[X.Y.Z]: https://github.com/toki-voki/maestro/compare/<prev>...vX.Y.Z`
     (first release: `.../releases/tag/vX.Y.Z`).

7. **Stop for approval.** Show the user:
   - the proposed version and why (step 5),
   - the full `git diff CHANGELOG.md`,
   - the exact GitHub release body: `scripts/changelog-section.sh vX.Y.Z`,
   - the commands from steps 8–10.

   Wait. Apply any edits they ask for and show it all again. Continue only on
   an explicit approval of this release ("approved", "ship it", "release it")
   — approval covers exactly this version's branch, commit, PR, merge, tag and
   tag push. Nothing before this step is committed or pushed.

8. **Land the changelog on main via PR** (subject only, no trailer, no
   "Generated with" footer in the PR body):
   ```bash
   git switch -c release/vX.Y.Z
   git add CHANGELOG.md
   git commit -m "docs(release): add vX.Y.Z changelog"
   git push -u origin release/vX.Y.Z
   gh pr create --base main --title "docs(release): add vX.Y.Z changelog" --body "Changelog for vX.Y.Z."
   gh pr checks --watch          # CI must be green
   gh pr merge --rebase --delete-branch   # main allows rebase merges only (linear history)
   ```

9. **Tag the merged commit on main** (annotated):
   ```bash
   git switch main && git pull --ff-only
   scripts/changelog-section.sh vX.Y.Z >/dev/null   # section is on main
   git tag -a vX.Y.Z -m "vX.Y.Z"
   git push origin vX.Y.Z
   ```

10. **Watch the release workflow**:
    ```bash
    gh run watch "$(gh run list --workflow release.yml --limit 1 --json databaseId -q '.[0].databaseId')"
    gh release view vX.Y.Z
    ```
    If it fails before publishing, report the failing step; do not move the
    tag — fix on main and release the next patch version.

11. **Report**: version, tag SHA, release URL, workflow run URL.

## Notes

- No AI/Co-Authored-By trailer on the commit, no "Generated with" footer in the
  release body (repo rule, see `CLAUDE.md`).
- Tag the changelog commit, not an earlier one, so the tag and its notes travel
  together.
- Never re-use or move a pushed tag. If a release is broken, ship the next
  patch version.
- Only repo admins should create `v*` tags — enforce it with a GitHub tag
  ruleset (Settings → Rules → Rulesets → Tags → restrict creation of `v*`).
