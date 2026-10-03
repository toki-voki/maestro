---
tags: [maestro, prd]
---
# Plugins
Back to [[Maestro PRD]] · Supports [[Principles|modularity]]

One plugin system for both [[Server]] and [[Client UI]].

## Requirements
- **PLG-1 (P1)** Embedded Lua runtime (Go: gopher-lua). Plugins are files in the config dir.
- **PLG-2 (P1)** Server hooks: pane output, pane exit, session created, agent state change → powers [[Agents]] detectors.
- **PLG-3 (P2)** Client hooks: custom status-bar segments, commands, keybindings, UI components.
- **PLG-4 (P2)** A broken plugin is disabled with an error, never crashes the server.
