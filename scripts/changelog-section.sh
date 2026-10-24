#!/bin/sh
# Print one release's section from CHANGELOG.md, for use as the GitHub release body.
#
#   scripts/changelog-section.sh v0.2.0            # section "## [0.2.0] - ..."
#   scripts/changelog-section.sh v0.2.0 CHANGELOG.md
#
# Exits 1 if the section is missing, so the release workflow can fall back.
set -eu

TAG="${1:?usage: changelog-section.sh vX.Y.Z [CHANGELOG.md]}"
FILE="${2:-CHANGELOG.md}"
VERSION="${TAG#v}"

SECTION="$(awk -v ver="$VERSION" '
    /^## \[/ {
        if (found) exit
        if (index($0, "## [" ver "]") == 1) { found = 1; next }
    }
    found && /^\[[^]]+\]: / { exit }   # link reference block at the bottom
    found { print }
' "$FILE")"

[ -n "$SECTION" ] || { echo "no section for ${TAG} in ${FILE}" >&2; exit 1; }

# trim leading/trailing blank lines
printf '%s\n' "$SECTION" | sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
