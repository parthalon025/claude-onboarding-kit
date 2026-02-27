#!/usr/bin/env bash
# Smoke-tests install.sh in a temp directory — verifies installed layout
set -euo pipefail
PASS=0; FAIL=0
check() { local desc="$1" result="$2"
  if [[ "$result" == "ok" ]]; then echo "[ok] $desc"; PASS=$((PASS+1))
  else echo "[!!] $desc"; FAIL=$((FAIL+1)); fi }

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Run install pointing KIT_DEST to temp location
KIT_DEST="$TMPDIR/.claude/kit" \
BIN_DEST="$TMPDIR/.local/bin" \
SKILLS_DEST="$TMPDIR/.claude/skills" \
  bash install.sh 2>&1 | grep -E '^\[' || true

# Core kit structure
check "kit/install marker" "$([ -d "$TMPDIR/.claude/kit" ] && echo ok || echo fail)"
check "kit/skills/ dir" "$([ -d "$TMPDIR/.claude/kit/skills" ] && echo ok || echo fail)"
check "kit/templates/ dir" "$([ -d "$TMPDIR/.claude/kit/templates" ] && echo ok || echo fail)"
check "kit/hooks/ dir" "$([ -d "$TMPDIR/.claude/kit/hooks" ] && echo ok || echo fail)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
