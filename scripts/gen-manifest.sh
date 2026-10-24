#!/bin/sh
# Generate latest.json from a GoReleaser dist/ directory. In CI the result is
# uploaded as an asset of the stable release (see release.yml); locally
# `make manifest` writes it to distribution/latest.json (gitignored) to inspect.
#
#   scripts/gen-manifest.sh [dist-dir] [out-file]
#
# One asset per line on purpose: distribution/install.sh parses it with grep/sed,
# so users don't need jq. Keep the layout if you touch this.
set -eu

DIST="${1:-dist}"
OUT="${2:-distribution/latest.json}"
REPO="toki-voki/maestro"

command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

TAG="$(jq -r '.tag' "$DIST/metadata.json")"
VERSION="$(jq -r '.version' "$DIST/metadata.json")"
DATE="$(jq -r '.date' "$DIST/metadata.json")"
BASE="https://github.com/${REPO}/releases/download/${TAG}"

mkdir -p "$(dirname "$OUT")"
{
    printf '{\n'
    printf '  "schema_version": 1,\n'
    printf '  "channel": "stable",\n'
    printf '  "version": "%s",\n' "$VERSION"
    printf '  "tag": "%s",\n' "$TAG"
    printf '  "date": "%s",\n' "$DATE"
    printf '  "assets": {\n'
    jq -r --arg base "$BASE" '
        [ .[] | select(.type == "Archive") ]
        | sort_by(.goos, .goarch)
        | length as $n
        | to_entries[]
        | .value as $a
        | "    \"\($a.goos)_\($a.goarch)\": {\"url\": \"\($base)/\($a.name)\", \"sha256\": \"\($a.extra.Checksum | ltrimstr("sha256:"))\"}\(if .key < ($n - 1) then "," else "" end)"
    ' "$DIST/artifacts.json"
    printf '  }\n'
    printf '}\n'
} > "$OUT"

jq empty "$OUT" # fail if we produced invalid JSON
echo "wrote $OUT ($TAG)"
