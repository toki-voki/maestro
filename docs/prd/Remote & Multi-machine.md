---
tags: [maestro, prd]
---
# Remote & Multi-machine
Back to [[Maestro PRD]] · Transport design: [[server-client-communication#4. Getting from the laptop to the remote socket|SSH relay]]

## Requirements
- **RMT-1 (P1)** Attach to a remote server over SSH via `maestrod --relay` (stdio ↔ socket). No custom auth.
- **RMT-2 (P1)** Hosts list in [[Configuration]]; the client connects to several at once.
- **RMT-3 (P1)** Unified session list across all hosts with [[Agents|agent states]] → [[Client UI]].
- **RMT-4 (P2)** Survive flaky links: reconnect + snapshot resync.
- **RMT-5 (P3)** TCP+TLS or WebSocket transport for [[Mobile]].
