---
tags: [maestro, prd]
---
# Configuration
Back to [[Maestro PRD]] · Follows [[Principles|git everything]]

## Requirements
- **CFG-1 (P0)** One config file in `~/.config/maestro/`; format TOML (YAML open → [[Open Questions]]).
- **CFG-2 (P1)** Hot reload on file change, for both [[Server]] and [[Client UI]].
- **CFG-3 (P1)** Covers keymap, status bar, themes, [[Agents|agent detectors]], [[Plugins]], [[Templates]] paths.
- **CFG-4 (P1)** Invalid config: keep the last good one and show the error.
- **CFG-5 (P2)** Themes as files; default scraped from terminal colors.
