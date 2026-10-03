---
tags: [maestro, prd, server]
---
# Templates
Back to [[Maestro PRD]] · Used by [[Sessions]]

A template is a session spec with variables (project path, name) — e.g. "editor + shell + agent" for any repo.

## Requirements
- **TPL-1 (P1)** Template = TOML session file plus `${vars}`; `maestro new -t ide path/`.
- **TPL-2 (P1)** Templates load from a config dir and from the project repo (`.maestro/`), so teams share them via git → [[Principles]].
- **TPL-3 (P2)** Pick a template from the [[Client UI]].

Scope still debated → [[Open Questions]].
