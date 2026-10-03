---
tags: [maestro, prd]
---
# Principles
Back to [[Maestro PRD]]

1. **Server is the source of truth.** Clients ask, the server decides and broadcasts. A client can crash or switch machines and nothing is lost. See [[Architecture]].
2. **Git everything.** Sessions, [[Templates]], [[Configuration]] and themes are plain text files that live in a repo and diff cleanly. Server state serializes back to the same format.
3. **Modular by default.** Every component (transport, emulator, agent detector, renderer, theme) sits behind an interface so it can be swapped or provided by a [[Plugins|plugin]].
4. **Detach never kills.** Closing a client never stops a pane.
5. **Raw bytes in, raw bytes out.** Keys go to the pane untouched except the prefix key — see [[server-client-communication#6. Sending keys from client to server|key handling]].
