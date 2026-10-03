---
tags: [maestro, prd, server]
---
# Agents
Back to [[Maestro PRD]] · Runs in [[Server]]

The core differentiator: the server knows which panes run an agent and what state it's in.

**States:** `idle` · `working` · `needs input` · `done` · `error`.

## Requirements
- **AGT-1 (P0)** Detect agent panes by process name (claude, codex, aider, …).
- **AGT-2 (P0)** Infer state with built-in heuristics: output activity, known prompt patterns, bell, process exit.
- **AGT-3 (P1)** Detectors are [[Plugins]] so new agents need no core change; hooks (e.g. Claude Code hooks) can push state directly instead of scraping.
- **AGT-4 (P1)** State is broadcast to clients and shown in the [[Client UI]] status bar and session list.
- **AGT-5 (P2)** Notification when an agent needs input (desktop, [[Mobile]]).
