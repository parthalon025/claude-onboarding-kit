#!/usr/bin/env bash
# Lesson anti-pattern scanner — checks staged/changed files against known bad patterns
# Usage: lesson-check [--project-root DIR] [--staged-only]
#
# Designed to run as a git pre-commit hook or standalone.
# Exit 0 = clean, Exit 1 = anti-patterns found.
set -euo pipefail

PROJECT_ROOT="."
STAGED_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-root) PROJECT_ROOT="$2"; shift 2 ;;
        --staged-only) STAGED_ONLY=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

cd "$PROJECT_ROOT"

# --- Get files to check ---
if [[ "$STAGED_ONLY" == "true" ]]; then
    FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
else
    FILES=$(git diff --name-only HEAD 2>/dev/null || true)
    if [[ -z "$FILES" ]]; then
        FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
    fi
fi

[[ -z "$FILES" ]] && exit 0

FINDINGS=0

check_pattern() {
    local label="$1" pattern="$2" file_filter="$3" severity="$4"

    while IFS= read -r file; do
        [[ -f "$file" ]] || continue

        # Apply file filter
        case "$file_filter" in
            "*.py") [[ "$file" == *.py ]] || continue ;;
            "*.sh") [[ "$file" == *.sh ]] || continue ;;
            "*") ;;
        esac

        if grep -qP "$pattern" "$file" 2>/dev/null; then
            LINE=$(grep -nP "$pattern" "$file" 2>/dev/null | head -1 | cut -d: -f1)
            echo "[$severity] $file:$LINE — $label"
            FINDINGS=$((FINDINGS + 1))
        fi
    done <<< "$FILES"
}

# --- Anti-pattern checks ---

# Bare exception swallowing (catch errors silently)
check_pattern "Bare except with pass/return (swallows errors silently)" \
    "except[^:]*:\s*(pass|return\b)" "*.py" "HIGH"

# async def without await (likely sync function marked async)
check_pattern "async def without any await in function body" \
    "^\s*async\s+def\s+\w+" "*.py" "MEDIUM"

# Hardcoded secrets patterns
check_pattern "Possible hardcoded secret or API key" \
    "(api_key|secret|password|token)\s*=\s*['\"][^'\"]{8,}" "*" "HIGH"

# create_task without done_callback
check_pattern "create_task without done_callback (errors may be swallowed)" \
    "create_task\(" "*.py" "MEDIUM"

# sqlite3 without closing() context manager
check_pattern "sqlite3.connect without closing() context manager" \
    "sqlite3\.connect\(" "*.py" "LOW"

# .venv/bin/pip instead of .venv/bin/python -m pip
check_pattern ".venv/bin/pip (use .venv/bin/python -m pip instead)" \
    "\.venv/bin/pip\s" "*.sh" "LOW"

# Hardcoded test count assertions
check_pattern "Hardcoded count assertion (fragile test)" \
    "assert\s+len\(\w+\)\s*==\s*\d+" "*.py" "LOW"

# --- Report ---
if (( FINDINGS > 0 )); then
    echo ""
    echo "Found $FINDINGS anti-pattern(s). Review before committing."
    exit 1
fi

exit 0
