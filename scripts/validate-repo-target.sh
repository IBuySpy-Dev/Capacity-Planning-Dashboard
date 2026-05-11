#!/usr/bin/env bash
set -euo pipefail

# Internal repository allowlist — deny by default
ALLOWLIST=(
  "ivegamsft/Capacity-Planning-Dashboard"
)

TARGET="${1:?Usage: validate-repo-target.sh <owner/repo>}"

for repo in "${ALLOWLIST[@]}"; do
  if [[ "$repo" == "$TARGET" ]]; then
    echo "✓ Repository '$TARGET' is on the internal allowlist."
    exit 0
  fi
done

echo "✗ BLOCKED: Repository '$TARGET' is NOT on the internal allowlist." >&2
echo "  GitHub write operations (issue/PR/comment create/edit/close) are denied." >&2
echo "  Update scripts/validate-repo-target.sh to add new repositories." >&2
exit 1
