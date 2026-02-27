#!/usr/bin/env bash
# Goal-reflection hook — injects goal context at session start
# Only runs for Claude Code sessions (local or remote)
set -euo pipefail

PIPELINE_STATUS="${CLAUDE_PROJECT_DIR:-$(pwd)}/tasks/pipeline-status.md"

if [[ ! -f "$PIPELINE_STATUS" ]]; then
  exit 0
fi

# Surface current pipeline phase to Claude
echo ""
echo "=== PROJECT STATUS ==="
grep '⬜\|🔨' "$PIPELINE_STATUS" | head -5
echo "====================="
echo ""
