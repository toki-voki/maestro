---
name: release
description: Cut a new maestro release — run every check, draft the CHANGELOG entry for the user to review and approve, land it on main via PR, then tag so the release workflow publishes. Use when the user says "release", "cut a version", "bump the tag", "increment the version", or "new maestro version".
---

# release

The procedure lives in `docs/development/release.md`. Read it in full and
follow it step by step; do not improvise around it.

Two hard stops from the doc, repeated here because they gate everything else:
**the checks must pass** before anything is written, and **the user must
approve the CHANGELOG entry** before anything is committed, tagged or pushed.
