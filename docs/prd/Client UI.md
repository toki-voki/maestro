---
tags: [maestro, prd, client]
---
# Client UI
Back to [[Maestro PRD]] · Part of [[Architecture]]

TUI client: renders server state and forwards input. Holds no state of its own.

## Requirements
**P0 — usable daily**
- **UI-1** Panes, splits and windows (tabs) rendered from server state.
- **UI-2** Prefix-key shortcuts (tmux-style), fully remappable.
- **UI-3** In-session status bar: session, windows, [[Agents|agent states]].

**P1 — overview**
- **UI-4** Session list with live state, across all servers → [[Remote & Multi-machine]].
- **UI-5** Window list with live preview of the selected window.
- **UI-6** Shortcut legend (`?`), generated from the active keymap.
- **UI-7** Mouse: focus, resize, scroll, select tabs.
- **UI-8** Settings view/modal over the [[Configuration]].

**P2 — polish**
- **UI-9** Themes; default derived from the host terminal's colors.
- **UI-10** Components are pluggable → [[Plugins]].
- **UI-11** Find sessions fast → [[Search & Tags]].
