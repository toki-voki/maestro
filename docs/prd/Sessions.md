---
tags: [maestro, prd, server]
---
# Sessions
Back to [[Maestro PRD]] · Owned by [[Server]]

Hierarchy: **session → windows (tabs) → panes**.

## Requirements
- **SES-1 (P0)** Create, attach, detach, rename, kill sessions, windows and panes.
- **SES-2 (P0)** Named sessions (`--session foo`) are fully separate server processes, each with its own socket. A crash in one never affects another.
- **SES-3 (P1)** Save/restore: state serializes to TOML (Tom's Obvious Minimal Language) and restores layout + commands after reboot.
- **SES-4 (P1)** `maestro apply session.toml` creates a session from a declarative spec → [[Templates]].
- **SES-5 (P2)** Tag sessions for grouping and filtering → [[Search & Tags]].

Listing across machines: [[Remote & Multi-machine]]. Example spec: [[server-client-communication#8. Changing sessions from the client|session TOML]].
