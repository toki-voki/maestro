---
tags: [maestro, prd]
---
# Architecture
Back to [[Maestro PRD]] · Full design: [[server-client-communication|Server–client communication]]

```
 client (TUI)  ──framed msgs──►  server (maestrod)
   render, input                 sessions → windows → panes → PTYs
                                 agent detection, plugins, save/restore
```

- **Transport:** generic byte stream. Unix socket locally, SSH stdio relay remotely → [[Remote & Multi-machine]].
- **Protocol:** length-prefixed frames; requests / responses / events; version in `Hello`.
- **Screen:** server streams raw PTY output and runs its own emulator for snapshot-on-attach.
- **State changes:** client sends `Cmd`, server mutates and broadcasts `StateChanged` to all clients.

Components: [[Server]] · [[Client UI]] · [[CLI]] · [[Plugins]]

## Requirements
- **ARC-1 (P0)** Protocol is transport-agnostic.
- **ARC-2 (P0)** Every message type is versioned; incompatible clients are rejected with a clear error.
- **ARC-3 (P1)** Backpressure: slow clients fall back to snapshot mode, never unbounded buffers.
