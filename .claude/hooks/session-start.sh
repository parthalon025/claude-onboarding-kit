#!/bin/bash
set -euo pipefail

# Only run on Claude Code web sessions
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Validate kit structure
bash tests/validate.sh 2>/dev/null || true
