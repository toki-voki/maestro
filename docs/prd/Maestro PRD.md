---
tags: [maestro, prd]
status: draft
updated: 2026-10-03
---
# Maestro — PRD

**M**ulti-**A**gent **E**xecution & **S**ession **T**erminal **R**untime **O**rchestrator

## Problem
Running many coding agents (Claude, Codex, …) across projects and machines means juggling tmux sessions, SSH tabs and guesswork about which agent is idle, busy or waiting for input. tmux owns the sessions but knows nothing about agents, has no cross-machine view, and is configured through a hard-to-version DSL (domain-specific language).

## Vision
A tmux-style terminal multiplexer whose server owns every session, pane and agent, and whose clients — local, remote or mobile — are thin views. One screen shows every session on every machine and what each agent is doing.

## Goals
1. Persistent sessions that survive client disconnects → [[Server]], [[Sessions]]
2. Know agent state at a glance → [[Agents]]
3. One view across machines → [[Remote & Multi-machine]]
4. Everything declarative and versionable → [[Principles]], [[Configuration]]
5. Extensible without forking → [[Plugins]]

## Non-goals (v1)
- Replacing the terminal emulator (Ghostty, iTerm2 stay the host).
- A GUI/web client — TUI (terminal UI) first; [[Mobile]] later.
- Our own auth/crypto — SSH is the transport.

## Users
- **Agent operator** — runs 3–10 agents in parallel, needs to see who's blocked.
- **Remote dev** — works on servers over SSH, wants sessions that persist.
- **Team** — shares session [[Templates]] via git.

## Map
| Area | Note |
|---|---|
| Foundations | [[Principles]] · [[Architecture]] |
| Server side | [[Server]] · [[Sessions]] · [[Templates]] · [[Agents]] · [[Plugins]] |
| Client side | [[Client UI]] · [[Search & Tags]] · [[CLI]] · [[Mobile]] |
| Cross-cutting | [[Configuration]] · [[Remote & Multi-machine]] · [[Updates]] |
| Planning | [[Roadmap]] · [[Open Questions]] |

## Success metrics
- Reattach after client crash loses **0** panes.
- Agent state shown within **≤1 s** of change.
- New project session from template in **1 command**.
- Daily driver for the core team, replacing tmux, by [[Roadmap#M3 — Agents|M3]].

## Sources
- [[PRD brainstorm]] — original feature dump
- [[server-client-communication|Server–client communication]] — protocol design
- [[errors|Error handling in Go]] — code conventions
