#!/usr/bin/env bash
# Improvement-loop hook — captures improvement prompts at session end
# Only runs for Claude Code sessions
set -euo pipefail

QUEUE_FILE="$HOME/.claude/.improvement-queue"
TIMESTAMP="$(date -Iseconds)"

# Rotate through improvement questions
QUESTIONS=(
  "What took the most tokens this session? Could a routing map or cached doc prevent it?"
  "Did this session touch an integration boundary (Cluster B)? Have you traced one value end-to-end?"
  "What would you do differently if starting this task over?"
  "What pattern did you repeat that could be automated?"
)

IDX=$(( $(wc -l < "$QUEUE_FILE" 2>/dev/null || echo 0) % ${#QUESTIONS[@]} ))
QUESTION="${QUESTIONS[$IDX]}"

echo "  - ($TIMESTAMP): IMPROVEMENT CAPTURE: $QUESTION" >> "$QUEUE_FILE"
