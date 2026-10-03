---
tags: [maestro, prd, source]
---
> Original brainstorm. Structured version: [[Maestro PRD]]

# Features overview:
- Naming
- UI
	- components
	- list all sessions (from multiple machines)
		- remote connection to mulitple servers
	- plugin architecture 
	- mouse support
	- tabs (windows)
	- shortcuts 
		- legend
	- session listing 
		- live watch 
	- windows 
		- listing
		- preview
	- templates (?)
	- configuration/setting view/modal
	- themes (best easiest practice)
		- terminal colors scrape is one idea
	- config
		- hot reload
	- cli support
	- search (method not agreed by all members)
		- tag
	- in session tui i.e tmux like bar 
	- automatic updates
	- *MOBILE SUPPORT*
- Server
	 holds all state: workspaces, tabs, panes, agent status detection, and save/restore of the session.

	 ### Features
	- Named sessions (--session foo) are fully separate servers, each with its own sockets.
	- attachable by multiple clients (machines)
	- ghostty-lib i.e terminal multiplexer
	- session creation
	- templates
	- agents 
		- plugins
		- heuristics
	- plugin architecture 
		- lua bato
	- cli support
	- config
		- hot reload
		- yaml/toml
	- update
  

# Philosophy 
- *git everything* feature
- make all components / object modular i.e flexible configurable 