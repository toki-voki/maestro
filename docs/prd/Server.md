---
tags: [maestro, prd, server]
---
# Server
Back to [[Maestro PRD]] · Part of [[Architecture]]

Long-lived daemon that owns all state: sessions, windows (tabs), panes, PTYs (pseudo-terminals), agent status and save/restore.

**Today:** `maestro server start` listens on `/tmp/maestro-<uid>/default.sock`, tracks clients, shuts down cleanly on SIGINT/SIGTERM. Stop is a stub.

## Requirements
- **SRV-1 (P0)** Spawn and own PTYs; survive client disconnects and the SSH session ending (`setsid`/launchd/systemd).
- **SRV-2 (P0)** Many clients attached at once, all seeing the same state.
- **SRV-3 (P0)** Server-side terminal emulator per pane for snapshot on attach. Candidate: libghostty — see [[Open Questions]].
- **SRV-4 (P0)** `server stop` / kill-server.
- **SRV-5 (P1)** Multi-client resize rule (smallest vs most-recent client).
- **SRV-6 (P1)** Save/restore full state to disk → [[Sessions]].
- **SRV-7 (P1)** Host [[Agents|agent detection]] and [[Plugins]].
- **SRV-8 (P2)** Hot-reload [[Configuration]] without restarting panes.

Conventions: [[errors|Error handling in Go]].
