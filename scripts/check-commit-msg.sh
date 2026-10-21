#!/bin/sh
# Validates a commit message file against the repo commit rules (see CLAUDE.md):
#   - subject: Conventional Commits `type(scope): summary`, scope required
#   - subject only, no body
#   - no AI co-author trailer or "Generated with" footer
# Used by .githooks/commit-msg and by CI.
#
# Usage: scripts/check-commit-msg.sh <message-file>

set -eu

file="${1:?usage: check-commit-msg.sh <message-file>}"

# Drop git comment lines and trailing blank lines.
msg="$(grep -v '^#' "$file" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')"
subject="$(printf '%s\n' "$msg" | head -n 1)"
rest="$(printf '%s\n' "$msg" | tail -n +2 | grep -v '^[[:space:]]*$' || true)"

fail() {
	echo "commit-msg: $1" >&2
	echo "  subject: $subject" >&2
	echo "  want:    type(scope): summary   e.g. feat(server): add unix socket hub" >&2
	exit 1
}

# Messages git generates itself.
case "$subject" in
"Merge "* | "fixup! "* | "squash! "* | "amend! "* | 'Revert "'*) exit 0 ;;
esac

types='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
if ! printf '%s\n' "$subject" | grep -Eq "^($types)\([a-z0-9][a-z0-9._/-]*\)!?: [^ ].*$"; then
	fail "subject is not Conventional Commits with a scope"
fi

if [ "${#subject}" -gt 72 ]; then
	fail "subject longer than 72 characters (${#subject})"
fi

if printf '%s\n' "$msg" | grep -Eiq '^co-authored-by:.*(claude|anthropic|copilot|gpt|openai|cursor|codex|bot)|generated with \[?claude'; then
	fail "AI co-author trailer or generated-with footer is not allowed"
fi

if [ -n "$rest" ]; then
	fail "subject line only, no body (split the change into several commits instead)"
fi
