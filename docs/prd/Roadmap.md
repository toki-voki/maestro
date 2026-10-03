---
tags: [maestro, prd]
---
# Roadmap
Back to [[Maestro PRD]] · Follows the build order in [[server-client-communication#Suggested build order|protocol doc]]

## M0 — Skeleton ✅ partly
Unix socket hub, `server start`, CLI dispatch. Next: one PTY piped to a raw-mode client.

## M1 — Local multiplexer
Framing + message types, multiple panes/windows, server emulator, snapshot on attach, detach/reattach.
→ [[Server]] SRV-1..4 · [[Sessions]] SES-1..2 · [[Client UI]] UI-1..3 · [[CLI]] CLI-1..2

## M2 — Declarative
Config file, TOML apply/save, templates, hot reload.
→ [[Configuration]] · [[Templates]] · [[Sessions]] SES-3..4

## M3 — Agents
Agent detection + states in status bar and session list. **Target: team daily driver.**
→ [[Agents]] · [[Client UI]] UI-4..6

## M4 — Remote
SSH relay, multi-host session list.
→ [[Remote & Multi-machine]]

## M5 — Extensible
Lua plugins, themes, search, updates.
→ [[Plugins]] · [[Search & Tags]] · [[Updates]]

## Later
[[Mobile]]
