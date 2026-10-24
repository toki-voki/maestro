# maestro

Go CLI with a background server and clients talking over a unix socket.

## Checks

`make check` runs what CI runs: format check (gofumpt + goimports), golangci-lint (`.golangci.yml`), `govulncheck`,
`go test -race`. Run it before every commit you are asked to make and before any release. `make fmt` fixes formatting,
`make tidy` fails if `go.mod`/`go.sum` are not tidy, `make release-check` validates `.goreleaser.yaml`.

Go toolchain is pinned by the `go` line in `go.mod` (GOTOOLCHAIN=auto downloads it if the local Go is older); CI reads
it from there via `go-version-file`. Upgrade with `go get go@1.26.N`.

## Git commits and releases

Commits: use the `commit` skill (`.claude/skills/commit/SKILL.md`). One commit per "commit", `type(scope): summary`
subject only, no AI trailer, `make check` first. Releases: use the `release` skill
(`.claude/skills/release/SKILL.md`); the procedure is in `docs/development/release.md`.

## Tickets

If a Linear ticket is given (or ask once if a code change has none), follow the `linear-ticket-flow` skill
(`.claude/skills/linear-ticket-flow/SKILL.md`): In Progress on start, In Review on PR, Done on merge. Skip if no Linear MCP.
