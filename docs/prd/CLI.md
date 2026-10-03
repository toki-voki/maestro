---
tags: [maestro, prd, client]
---
# CLI
Back to [[Maestro PRD]] · A client per [[Architecture]]

Every UI action is also a CLI command: a short-lived client that sends one `Cmd` and exits. Makes Maestro scriptable and lets agents drive it.

**Today:** `maestro server start|stop`, `maestro client start` (stop and client are stubs).

## Requirements
- **CLI-1 (P0)** `maestro` with no args attaches (starts server if needed).
- **CLI-2 (P0)** `new`, `attach`, `ls`, `kill`, `send-keys`, `split`, `rename`.
- **CLI-3 (P1)** `apply <file>` / `save <session>` → [[Sessions]], [[Templates]].
- **CLI-4 (P1)** `--json` output for scripts and agents.
- **CLI-5 (P1)** `--session foo` and `--host` select target server → [[Remote & Multi-machine]].
