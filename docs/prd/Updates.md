---
tags: [maestro, prd]
---
# Updates
Back to [[Maestro PRD]]

## Requirements
- **UPD-1 (P2)** `maestro update` self-update from GitHub releases; checksum verified.
- **UPD-2 (P2)** Optional background check, notice in the [[Client UI]].
- **UPD-3 (P2)** Restarting the [[Server]] binary keeps running panes (state handoff or [[Sessions|save/restore]]).
- **UPD-4 (P2)** Client/server version mismatch is detected via protocol version → [[Architecture]].
