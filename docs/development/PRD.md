---
tags: [maestro, prd]
status: draft
updated: 2026-10-19
---
# Maestro — PRD

**M**ulti-**A**gent **E**xecution & **S**ession **T**erminal **R**untime **O**rchestrator

Requirement IDs: `AREA-n (Px)`. P0 = needed to replace tmux daily, P1 = needed for the team, P2 = polish, P3 = later.

**Contents**
1. [Overview](#1-overview) — problem, vision, goals, users, metrics
2. [Principles](#2-principles)
3. [Architecture](#3-architecture)
4. [Server side](#4-server-side) — Server · Sessions · Templates · Agents · Plugins
5. [Client side](#5-client-side) — Client UI · Search & Tags · CLI · Mobile
6. [Cross-cutting](#6-cross-cutting) — Configuration · Remote & Multi-machine · Updates · Distribution & Release
7. [Roadmap](#7-roadmap)
8. [Open questions](#8-open-questions)
9. [Appendix: original brainstorm](#9-appendix-original-brainstorm)

Related design doc: [Server–client communication](server-client-communication.md) (protocol).

---

## 1. Overview

### Problem
Running many coding agents (Claude, Codex, …) across projects and machines means juggling tmux sessions, SSH tabs and guesswork about which agent is idle, busy or waiting for input. tmux owns the sessions but knows nothing about agents, has no cross-machine view, and is configured through a hard-to-version DSL (domain-specific language).

### Vision
A tmux-style terminal multiplexer whose server owns every session, pane and agent, and whose clients — local, remote or mobile — are thin views. One screen shows every session on every machine and what each agent is doing.

### Goals
1. Persistent sessions that survive client disconnects → [Server](#server), [Sessions](#sessions)
2. Know agent state at a glance → [Agents](#agents)
3. One view across machines → [Remote & Multi-machine](#remote--multi-machine)
4. Everything declarative and versionable → [Principles](#2-principles), [Configuration](#configuration)
5. Extensible without forking → [Plugins](#plugins)

### Non-goals (v1)
- Replacing the terminal emulator (Ghostty, iTerm2 stay the host).
- A GUI/web client — TUI (terminal UI) first; [Mobile](#mobile) later.
- Our own auth/crypto — SSH is the transport.

### Users
- **Agent operator** — runs 3–10 agents in parallel, needs to see who's blocked.
- **Remote dev** — works on servers over SSH, wants sessions that persist.
- **Team** — shares session [Templates](#templates) via git.

### Success metrics
- Reattach after client crash loses **0** panes.
- Agent state shown within **≤1 s** of change.
- New project session from template in **1 command**.
- Daily driver for the core team, replacing tmux, by [M3](#m3--agents).

---

## 2. Principles

1. **Server is the source of truth.** Clients ask, the server decides and broadcasts. A client can crash or switch machines and nothing is lost. See [Architecture](#3-architecture).
2. **Git everything.** Sessions, [Templates](#templates), [Configuration](#configuration) and themes are plain text files that live in a repo and diff cleanly. Server state serializes back to the same format.
3. **Modular by default.** Every component (transport, emulator, agent detector, renderer, theme) sits behind an interface so it can be swapped or provided by a [plugin](#plugins).
4. **Detach never kills.** Closing a client never stops a pane.
5. **Raw bytes in, raw bytes out.** Keys go to the pane untouched except the prefix key — see [key handling](server-client-communication.md#6-sending-keys-from-client-to-server).

---

## 3. Architecture

Full design: [Server–client communication](server-client-communication.md).

```
 client (TUI)  ──framed msgs──►  server (maestrod)
   render, input                 sessions → windows → panes → PTYs
                                 agent detection, plugins, save/restore
```

- **Transport:** generic byte stream. Unix socket locally, SSH stdio relay remotely → [Remote & Multi-machine](#remote--multi-machine).
- **Protocol:** length-prefixed frames; requests / responses / events; version in `Hello`.
- **Screen:** server streams raw PTY output and runs its own emulator for snapshot-on-attach.
- **State changes:** client sends `Cmd`, server mutates and broadcasts `StateChanged` to all clients.

Components: [Server](#server) · [Client UI](#client-ui) · [CLI](#cli) · [Plugins](#plugins)

**Requirements**
- **ARC-1 (P0)** Protocol is transport-agnostic.
- **ARC-2 (P0)** Every message type is versioned; incompatible clients are rejected with a clear error.
- **ARC-3 (P1)** Backpressure: slow clients fall back to snapshot mode, never unbounded buffers.

---

## 4. Server side

### Server
Long-lived daemon that owns all state: sessions, windows (tabs), panes, PTYs (pseudo-terminals), agent status and save/restore.

**Today:** `maestro server start` listens on `/tmp/maestro-<uid>/default.sock`, tracks clients, shuts down cleanly on SIGINT/SIGTERM. Stop is a stub.

- **SRV-1 (P0)** Spawn and own PTYs; survive client disconnects and the SSH session ending (`setsid`/launchd/systemd).
- **SRV-2 (P0)** Many clients attached at once, all seeing the same state.
- **SRV-3 (P0)** Server-side terminal emulator per pane for snapshot on attach. Candidate: libghostty — see [Open questions](#8-open-questions) #2.
- **SRV-4 (P0)** `server stop` / kill-server.
- **SRV-5 (P1)** Multi-client resize rule (smallest vs most-recent client) — [Open questions](#8-open-questions) #6.
- **SRV-6 (P1)** Save/restore full state to disk → [Sessions](#sessions).
- **SRV-7 (P1)** Host [agent detection](#agents) and [Plugins](#plugins).
- **SRV-8 (P2)** Hot-reload [Configuration](#configuration) without restarting panes.

### Sessions
Hierarchy: **session → windows (tabs) → panes**. Owned by the [Server](#server).

- **SES-1 (P0)** Create, attach, detach, rename, kill sessions, windows and panes.
- **SES-2 (P0)** Named sessions (`--session foo`) are fully separate server processes, each with its own socket. A crash in one never affects another.
- **SES-3 (P1)** Save/restore: state serializes to TOML (Tom's Obvious Minimal Language) and restores layout + commands after reboot.
- **SES-4 (P1)** `maestro apply session.toml` creates a session from a declarative spec → [Templates](#templates).
- **SES-5 (P2)** Tag sessions for grouping and filtering → [Search & Tags](#search--tags).

Listing across machines: [Remote & Multi-machine](#remote--multi-machine). Example spec: [session TOML](server-client-communication.md#8-changing-sessions-from-the-client).

### Templates
A template is a session spec with variables (project path, name) — e.g. "editor + shell + agent" for any repo. Used by [Sessions](#sessions).

- **TPL-1 (P1)** Template = TOML session file plus `${vars}`; `maestro new -t ide path/`.
- **TPL-2 (P1)** Templates load from a config dir and from the project repo (`.maestro/`), so teams share them via git → [Principles](#2-principles).
- **TPL-3 (P2)** Pick a template from the [Client UI](#client-ui).

Scope still debated → [Open questions](#8-open-questions) #5.

### Agents
The core differentiator: the server knows which panes run an agent and what state it's in.

**States:** `idle` · `working` · `needs input` · `done` · `error`.

- **AGT-1 (P0)** Detect agent panes by process name (claude, codex, aider, …).
- **AGT-2 (P0)** Infer state with built-in heuristics: output activity, known prompt patterns, bell, process exit.
- **AGT-3 (P1)** Detectors are [Plugins](#plugins) so new agents need no core change; hooks (e.g. Claude Code hooks) can push state directly instead of scraping — [Open questions](#8-open-questions) #9.
- **AGT-4 (P1)** State is broadcast to clients and shown in the [Client UI](#client-ui) status bar and session list.
- **AGT-5 (P2)** Notification when an agent needs input (desktop, [Mobile](#mobile)).

### Plugins
One plugin system for both [Server](#server) and [Client UI](#client-ui). Supports [modularity](#2-principles).

- **PLG-1 (P1)** Embedded Lua runtime (Go: gopher-lua). Plugins are files in the config dir — language open, [Open questions](#8-open-questions) #7.
- **PLG-2 (P1)** Server hooks: pane output, pane exit, session created, agent state change → powers [Agents](#agents) detectors.
- **PLG-3 (P2)** Client hooks: custom status-bar segments, commands, keybindings, UI components.
- **PLG-4 (P2)** A broken plugin is disabled with an error, never crashes the server.

---

## 5. Client side

### Client UI
TUI client: renders server state and forwards input. Holds no state of its own.

**P0 — usable daily**
- **UI-1** Panes, splits and windows (tabs) rendered from server state.
- **UI-2** Prefix-key shortcuts (tmux-style), fully remappable.
- **UI-3** In-session status bar: session, windows, [agent states](#agents).

**P1 — overview**
- **UI-4** Session list with live state, across all servers → [Remote & Multi-machine](#remote--multi-machine).
- **UI-5** Window list with live preview of the selected window.
- **UI-6** Shortcut legend (`?`), generated from the active keymap.
- **UI-7** Mouse: focus, resize, scroll, select tabs.
- **UI-8** Settings view/modal over the [Configuration](#configuration).

**P2 — polish**
- **UI-9** Themes; default derived from the host terminal's colors.
- **UI-10** Components are pluggable → [Plugins](#plugins).
- **UI-11** Find sessions fast → [Search & Tags](#search--tags).

### Search & Tags
- **SRC-1 (P2)** Fuzzy jump to any session/window/pane by name across all servers.
- **SRC-2 (P2)** Tags on sessions (`work`, `agent`, project) with filter in the session list → [Sessions](#sessions).
- **SRC-3 (P3)** Search pane scrollback.

Method not agreed by the team → [Open questions](#8-open-questions) #4.

### CLI
Every UI action is also a CLI command: a short-lived client that sends one `Cmd` and exits. Makes Maestro scriptable and lets agents drive it.

**Today:** `maestro server start|stop`, `maestro client start`, `maestro version` (stop and client are stubs).

- **CLI-1 (P0)** `maestro` with no args attaches (starts server if needed).
- **CLI-2 (P0)** `new`, `attach`, `ls`, `kill`, `send-keys`, `split`, `rename`.
- **CLI-3 (P1)** `apply <file>` / `save <session>` → [Sessions](#sessions), [Templates](#templates).
- **CLI-4 (P1)** `--json` output for scripts and agents.
- **CLI-5 (P1)** `--session foo` and `--host` select target server → [Remote & Multi-machine](#remote--multi-machine).

### Mobile
Goal: check on and unblock agents from a phone. Not a full terminal experience.

- **MOB-1 (P2)** Read-only session list with [agent states](#agents).
- **MOB-2 (P2)** Push notification when an agent needs input.
- **MOB-3 (P3)** Reply to an agent prompt / send keys to one pane.

Needs a non-SSH transport → RMT-5. Form factor open → [Open questions](#8-open-questions) #8.

---

## 6. Cross-cutting

### Configuration
Follows [git everything](#2-principles).

- **CFG-1 (P0)** One config file in `~/.config/maestro/`; format TOML (YAML open → [Open questions](#8-open-questions) #3).
- **CFG-2 (P1)** Hot reload on file change, for both [Server](#server) and [Client UI](#client-ui).
- **CFG-3 (P1)** Covers keymap, status bar, themes, [agent detectors](#agents), [Plugins](#plugins), [Templates](#templates) paths.
- **CFG-4 (P1)** Invalid config: keep the last good one and show the error.
- **CFG-5 (P2)** Themes as files; default scraped from terminal colors.

### Remote & Multi-machine
Transport design: [SSH relay](server-client-communication.md#4-getting-from-the-laptop-to-the-remote-socket).

- **RMT-1 (P1)** Attach to a remote server over SSH via `maestrod --relay` (stdio ↔ socket). No custom auth.
- **RMT-2 (P1)** Hosts list in [Configuration](#configuration); the client connects to several at once.
- **RMT-3 (P1)** Unified session list across all hosts with [agent states](#agents) → [Client UI](#client-ui).
- **RMT-4 (P2)** Survive flaky links: reconnect + snapshot resync.
- **RMT-5 (P3)** TCP+TLS or WebSocket transport for [Mobile](#mobile).

### Updates
- **UPD-1 (P2)** `maestro update` self-update; reads `distribution/latest.json` and verifies the sha256 it carries → DST-6.
- **UPD-2 (P2)** Optional background check, notice in the [Client UI](#client-ui).
- **UPD-3 (P2)** Restarting the [Server](#server) binary keeps running panes (state handoff or [save/restore](#sessions)).
- **UPD-4 (P2)** Client/server version mismatch is detected via protocol version → [Architecture](#3-architecture).

### Distribution & Release
How maestro is built, checked, versioned and put in users' hands. One Makefile locally, two GitHub workflows remotely, GoReleaser in the middle.

**Today:** `make check` = CI; `git push origin vX.Y.Z` publishes binaries for 6 platforms, deb/rpm/apk, a Homebrew cask and `distribution/latest.json`; `distribution/install.sh` installs from that manifest with SHA-256 verification. Nothing released yet — first tag is `v0.1.0` once this lands on `main`.

- **DST-1 (P0)** One command runs every check CI runs (`make check`: format, lint incl. gosec, govulncheck, race tests). Same result locally and in CI.
- **DST-2 (P0)** Pushing a `v*` tag is the only manual publish step; everything else is automated and reproducible from the tag.
- **DST-3 (P0)** Prebuilt, stripped, CGO-free binaries for linux/darwin/windows × amd64/arm64, with `checksums.txt`.
- **DST-4 (P0)** `maestro version` prints the tag the binary was built from (ldflags → `cli.version`).
- **DST-5 (P0)** One-line install for Linux/macOS that verifies the download before installing; never `curl | sh` an unverified binary.
- **DST-6 (P1)** Each stable release carries a `latest.json` asset (version, tag, per-platform url + sha256); `install.sh` reads it through GitHub's "Latest" pointer, so a bad release is rolled back with one command (`gh release edit vX.Y.Z --latest`), no commit → UPD-1.
- **DST-7 (P1)** Homebrew tap, deb/rpm/apk packages. homebrew-core once notable enough.
- **DST-8 (P1)** Pre-release tags (`v0.2.0-rc1`) publish to GitHub only: no tap update, no manifest update.
- **DST-9 (P1)** Release notes are the version's section of `CHANGELOG.md`, approved by a human before tagging. No AI trailers or footers.
- **DST-10 (P2)** Windows install script (`install.ps1`). Scoop/winget via GoReleaser blocks.
- **DST-11 (P2)** Nightly channel built from `main`. Not before external users ask for it.
- **DST-12 (P1)** Commit messages are machine-checked: Conventional Commits with scope, subject only, no AI trailer. `.githooks/commit-msg` (enable once with `make hooks`) locally, `commits` job in CI, both via `scripts/check-commit-msg.sh`.

**Build & checks**

| `make` target | runs | note |
|---|---|---|
| `build` | `go build -trimpath -ldflags "-s -w -X …/cli.version=$(git describe)"` → `bin/maestro` | `-s -w` strips debug info; `-X` injects version |
| `link` | `ln -sfn bin/maestro $GOPATH/bin/maestro` | once; then `maestro` is always the latest `make build` |
| `fmt` / `fmt-check` | `golangci-lint fmt` | gofumpt + goimports, local-prefix grouping |
| `lint` | `golangci-lint run` | `.golangci.yml`: standard set + gosec, errorlint, gocritic, revive, misspell, … |
| `lint-windows` | `GOOS=windows golangci-lint run` | we ship Windows binaries; `_windows.go` and syscall code is otherwise unlinted |
| `vuln` | `go tool govulncheck ./...` | CVEs in deps your code actually calls, incl. stdlib |
| `osv-check` | `osv-scanner scan --lockfile=go.mod` | broader advisory sources (GitHub, OSV), no reachability analysis, so it complements govulncheck |
| `test` | `go test -race -cover ./...` | |
| `check` | fmt-check lint lint-windows vuln osv-check test | pre-commit and pre-release gate; CI runs exactly this |
| `tidy` | `go mod tidy` + fail on diff | |
| `release-check` / `release-snapshot` / `manifest` | goreleaser validate / full build into `dist/` / regenerate `latest.json` | dry runs, publish nothing |
| `tools` / `clean-tools` | install / remove `.bin/` | targets install on demand anyway |
| `hooks` | `git config core.hooksPath .githooks` | once per clone |

Tooling without global installs. Two mechanisms: govulncheck is a `tool` directive in `go.mod` (`go tool govulncheck`, versioned by go.sum). golangci-lint, osv-scanner and goreleaser have dependency graphs too big to pull into go.sum, so they are pinned in the Makefile and `go install`ed into a gitignored per-checkout `.bin/` on first use, with the version in the filename (`.bin/golangci-lint-v2.14.0`) so a bump reinstalls automatically. A preinstalled copy on PATH is never used, so local and CI agree. CI caches `.bin/` keyed on the Makefile hash. A fresh clone needs only Go.

Go version: the `go` line in `go.mod` (`1.27.3`, latest stable) is both minimum and toolchain. `GOTOOLCHAIN=auto` downloads it if local Go is older; CI reads it through `setup-go`'s `go-version-file`; the `.bin/` tools are built with that same version (it is in their filename, so a bump rebuilds them). Upgrade: `go get go@<latest>`, `make check`, commit `go.mod`. Anything below 1.26.3 fails govulncheck on GO-2026-4971 (`server.NewHub` → `net.Listen`).

**CI** (`.github/workflows/ci.yml`): on push to `main` and every PR. Five parallel jobs, each a make target so CI and local runs are the same commands with the same pinned versions: **lint** (`make fmt-check lint lint-windows`), **test** (`make test`), **vuln** (`make vuln osv-check`), **snapshot** (goreleaser action pinned to the Makefile's version, snapshot build, publishes nothing), **commits** (PR title + each commit subject through `scripts/check-commit-msg.sh`). Branches without a PR run nothing. `release.yml` runs `make check` before publishing.

**Release** (`.github/workflows/release.yml`):

```
git push origin v0.1.0
  │
  ├─ 1. lint + go test -race           (red here = burned tag → run `make check` BEFORE tagging)
  ├─ 2. scripts/changelog-section.sh   CHANGELOG.md "## [0.1.0]" → release body (fallback: commit log)
  ├─ 3. goreleaser (.goreleaser.yaml)
  │       6 binaries → maestro_0.1.0_<os>_<arch>.tar.gz|zip + checksums.txt
  │       deb / rpm / apk (nfpm)
  │       GitHub release, prerelease: auto
  │       Casks/maestro.rb → toki-voki/homebrew-tap   (skip_upload: auto → rc tags skip)
  └─ 4. stable tags only: scripts/gen-manifest.sh → latest.json → gh release upload (asset on this release)
```

Job declares `contents: write`. Secret `HOMEBREW_TAP_TOKEN` (fine-grained PAT, `contents: write` on the tap repo) is required while the cask block exists.

**Channels**

| | stable `v0.2.0` | pre-release `v0.2.0-rc1` | nightly |
|---|---|---|---|
| GitHub release | yes, "latest" | yes, flagged pre-release | not built (DST-11) |
| Homebrew tap | updated | skipped | — |
| `latest.json` | uploaded as asset, served via `releases/latest/download/` | not uploaded, never "Latest" | — |
| `install.sh` default | installs | only with `MAESTRO_VERSION=v0.2.0-rc1` | — |

GitHub's own "Latest" flag = newest non-pre-release, movable with `gh release edit vX.Y.Z --latest`; `https://github.com/toki-voki/maestro/releases/latest/download/latest.json` redirects to the flagged release's asset. `latest.json` itself: version, tag, date, per-platform `{url, sha256}`, one asset per line so a POSIX installer parses it without jq. Same shape as herdr's `latest.json`. Nothing in the pipeline writes to `main`.

**Install**

```sh
curl -fsSL https://raw.githubusercontent.com/toki-voki/maestro/main/distribution/install.sh | sh
```

| method | command |
|---|---|
| Homebrew | `brew install toki-voki/tap/maestro` |
| Go | `go install github.com/toki-voki/maestro@latest` |
| mise | `mise use -g ubi:toki-voki/maestro` |
| deb / rpm / apk / Windows zip | GitHub releases page |

`install.sh`: detect OS+arch → fetch `latest.json` → download archive → sha256 (sha256sum / shasum / openssl) → refuse on mismatch → `install -m 0755` into `~/.local/bin` → if not on PATH, print the right line for the login shell (fish `fish_add_path`, zsh/bash `export`). Never edits shell config unless `MAESTRO_MODIFY_PATH=1`. Other overrides: `MAESTRO_VERSION`, `MAESTRO_INSTALL_DIR`, `MAESTRO_MANIFEST_URL`.

**Cutting a release** — driven by the `release` skill (`.claude/skills/release/SKILL.md`), which stops for approval of the changelog entry:

1. clean `main`, `make check release-check release-snapshot` green
2. `CHANGELOG.md`: `[Unreleased]` → `[X.Y.Z] - YYYY-MM-DD`, new empty `[Unreleased]`, fix link refs; `scripts/changelog-section.sh vX.Y.Z` shows the release body
3. PR `docs(release): add vX.Y.Z changelog` → merge
4. `git tag -a vX.Y.Z -m vX.Y.Z && git push origin vX.Y.Z` → `gh run watch`

Bump: `feat` → minor, only `fix` → patch, breaking → minor while `0.x`. Never move or reuse a pushed tag; broken release → next patch. Every user-visible change adds a line under `[Unreleased]` in the PR that makes it.

**Repo rules**
- `main`: PR required (0 approvals), rebase merges only so history stays linear (GitHub has no true fast-forward button; rebase is the closest: no merge commit, commits replayed with new SHAs), no force-push, no deletion, empty bypass list (the release workflow never writes to `main`; a GitHub Actions bypass actor is not even accepted on org-owned repos unless the app is installed in the org). Merge with `gh pr merge --rebase`. Ruleset: `.github/rulesets/protect-main.json`, applied as ruleset 25779654; re-apply after edits with `gh api repos/toki-voki/maestro/rulesets/25779654 -X PUT --input .github/rulesets/protect-main.json`.
- Tags: optionally restrict `v*` creation to admins (tag ruleset, GitHub UI).
- One-time: create empty repo `toki-voki/homebrew-tap` + `HOMEBREW_TAP_TOKEN` secret, or delete the `homebrew_casks` block.

Files: `Makefile` · `.golangci.yml` · `.goreleaser.yaml` · `.github/workflows/{ci,release}.yml` · `.github/rulesets/protect-main.json` · `.githooks/commit-msg` · `distribution/install.sh` · `scripts/{gen-manifest,changelog-section,check-commit-msg}.sh` · `CHANGELOG.md` · `.claude/skills/release/SKILL.md`

---

## 7. Roadmap
Follows the build order in the [protocol doc](server-client-communication.md#suggested-build-order).

### M0 — Skeleton ✅ partly
Unix socket hub, `server start`, CLI dispatch, build/check/release pipeline ([Distribution & Release](#distribution--release)). Next: one PTY piped to a raw-mode client, then tag `v0.1.0`.

### M1 — Local multiplexer
Framing + message types, multiple panes/windows, server emulator, snapshot on attach, detach/reattach.
→ SRV-1..4 · SES-1..2 · UI-1..3 · CLI-1..2

### M2 — Declarative
Config file, TOML apply/save, templates, hot reload.
→ CFG-* · TPL-* · SES-3..4

### M3 — Agents
Agent detection + states in status bar and session list. **Target: team daily driver.**
→ AGT-* · UI-4..6

### M4 — Remote
SSH relay, multi-host session list.
→ RMT-*

### M5 — Extensible
Lua plugins, themes, search, updates.
→ PLG-* · SRC-* · UPD-*

### Later
[Mobile](#mobile).

---

## 8. Open questions

| # | Question | Options | Affects |
|---|---|---|---|
| 1 | Final name | Maestro (keep) / other | whole PRD |
| 2 | Server terminal emulator | libghostty (C ABI, cgo) / pure-Go vt parser | SRV-3 |
| 3 | Config format | TOML / YAML | CFG-1 |
| 4 | Search method | fuzzy names / tags / full-text scrollback | SRC-* |
| 5 | Templates: separate concept or just session files? | | TPL-* |
| 6 | Multi-client resize rule | smallest / most recent | SRV-5 |
| 7 | Plugin language | Lua / WASM | PLG-1 |
| 8 | Mobile form factor | native app / web client / chat bot | MOB-* |
| 9 | Agent state: scrape vs hooks first | | AGT-3 |

---

## 9. Appendix: original brainstorm
Raw feature dump the sections above were structured from. Kept as source.

**Features overview**
- Naming
- UI
	- components
	- list all sessions (from multiple machines)
		- remote connection to multiple servers
	- plugin architecture
	- mouse support
	- tabs (windows)
	- shortcuts
		- legend
	- session listing
		- live watch
	- windows
		- listing
		- preview
	- templates (?)
	- configuration/setting view/modal
	- themes (best easiest practice)
		- terminal colors scrape is one idea
	- config
		- hot reload
	- cli support
	- search (method not agreed by all members)
		- tag
	- in session tui i.e tmux like bar
	- automatic updates
	- *MOBILE SUPPORT*
- Server — holds all state: workspaces, tabs, panes, agent status detection, and save/restore of the session.
	- Named sessions (--session foo) are fully separate servers, each with its own sockets.
	- attachable by multiple clients (machines)
	- ghostty-lib i.e terminal multiplexer
	- session creation
	- templates
	- agents
		- plugins
		- heuristics
	- plugin architecture
		- lua bato
	- cli support
	- config
		- hot reload
		- yaml/toml
	- update

**Philosophy**
- *git everything* feature
- make all components / objects modular i.e flexible configurable
