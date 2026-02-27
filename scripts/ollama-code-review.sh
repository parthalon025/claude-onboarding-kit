#!/usr/bin/env bash
# Ollama Code Review — batch source files by directory through a local LLM
# Usage: ollama-code-review [options] <project-dir>
#
# Options:
#   --src-dir DIR     Source directory to scan (default: auto-detect)
#   --lang LANG       Language filter: python, typescript, javascript (default: auto-detect)
#   --model MODEL     Ollama model to use (default: from config or qwen2.5-coder:14b)
#   --output FILE     Output file (default: /tmp/ollama-review-<project>-<date>.md)
#
# Requires: ollama running locally, curl, jq
set -euo pipefail

# --- Parse arguments ---
SRC_DIR=""
LANG=""
MODEL=""
OUTPUT=""
PROJECT_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --src-dir) SRC_DIR="$2"; shift 2 ;;
        --lang) LANG="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) PROJECT_DIR="$1"; shift ;;
    esac
done

[[ -z "$PROJECT_DIR" ]] && { echo "Usage: ollama-code-review [options] <project-dir>" >&2; exit 1; }
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# --- Load config ---
KIT_CONFIG="${CLAUDE_KIT_DIR:-$HOME/.claude/kit}/config.env"
if [[ -f "$KIT_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$KIT_CONFIG"
fi

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
MODEL="${MODEL:-${OLLAMA_REVIEW_MODEL:-qwen2.5-coder:14b}}"
OUTPUT="${OUTPUT:-/tmp/ollama-review-$(basename "$PROJECT_DIR")-$(date +%Y%m%d-%H%M%S).md}"
MAX_CHARS=200000  # ~50K tokens, leaves room for prompt + response in 128K context

# --- Auto-detect language and source directory ---
if [[ -z "$LANG" ]]; then
    if [[ -f "$PROJECT_DIR/package.json" ]]; then
        if [[ -f "$PROJECT_DIR/tsconfig.json" ]]; then
            LANG="typescript"
        else
            LANG="javascript"
        fi
    elif [[ -f "$PROJECT_DIR/pyproject.toml" ]] || [[ -f "$PROJECT_DIR/setup.py" ]]; then
        LANG="python"
    else
        LANG="python"  # default fallback
    fi
fi

if [[ -z "$SRC_DIR" ]]; then
    if [[ -d "$PROJECT_DIR/src" ]]; then
        SRC_DIR="$PROJECT_DIR/src"
    else
        SRC_DIR="$PROJECT_DIR"
    fi
fi

# --- Set file extension filter ---
case "$LANG" in
    python) FILE_EXT="*.py" ;;
    typescript) FILE_EXT="*.ts" ;;
    javascript) FILE_EXT="*.js" ;;
    *) FILE_EXT="*.py" ;;
esac

# --- Check ollama is reachable ---
if ! curl -s --max-time 5 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "ERROR: Ollama not reachable at $OLLAMA_URL" >&2
    echo "Start ollama or set OLLAMA_URL in config" >&2
    exit 1
fi

# --- Review prompt ---
REVIEW_PROMPT="You are reviewing $LANG source code. Review for:

1. **Bugs & Logic Errors** — off-by-one, missing awaits, race conditions, unhandled exceptions
2. **Security** — injection risks, unsafe deserialization, exposed secrets, missing input validation
3. **Performance** — N+1 queries, unbounded loops, missing caching, memory leaks
4. **Code Quality** — dead code, duplicated logic, overly complex functions (>50 lines), unclear naming
5. **Async Issues** — blocking calls in async context, missing await, improper lock usage

For each finding, output EXACTLY this format:
**[SEVERITY: HIGH/MEDIUM/LOW]** \`filename:line_approx\` — description

Only report actual issues. Do not praise code or add summaries. Be specific about line numbers."

# --- Build batches ---
echo "# Ollama Code Review: $(basename "$PROJECT_DIR")" > "$OUTPUT"
echo "Model: $MODEL | Language: $LANG | Date: $(date -Iseconds)" >> "$OUTPUT"
echo "" >> "$OUTPUT"

declare -a BATCHES=()
declare -a BATCH_NAMES=()

add_batch() {
    local name="$1"
    shift
    local files=("$@")
    local content=""
    local chars=0

    for f in "${files[@]}"; do
        local rel_path="${f#"$PROJECT_DIR"/}"
        local file_content
        file_content=$(cat "$f" 2>/dev/null) || continue
        local file_chars=${#file_content}

        if (( chars + file_chars > MAX_CHARS )); then
            if [[ -n "$content" ]]; then
                BATCHES+=("$content")
                BATCH_NAMES+=("$name (part)")
            fi
            content=""
            chars=0
        fi

        content+="
--- FILE: $rel_path ---
$file_content
"
        chars=$(( chars + file_chars + ${#rel_path} + 20 ))
    done

    if [[ -n "$content" ]]; then
        BATCHES+=("$content")
        BATCH_NAMES+=("$name")
    fi
}

# Group files by directory
while IFS= read -r dir; do
    files=()
    while IFS= read -r f; do
        files+=("$f")
    done < <(find "$dir" -maxdepth 1 -name "$FILE_EXT" -not -path "*/node_modules/*" -not -path "*/.venv/*" -not -path "*/dist/*" -not -path "*/__pycache__/*" | sort)

    [[ ${#files[@]} -eq 0 ]] && continue

    dir_name="${dir#"$SRC_DIR"/}"
    [[ "$dir_name" == "$dir" ]] && dir_name="root"

    add_batch "$dir_name" "${files[@]}"
done < <(find "$SRC_DIR" -name "$FILE_EXT" -not -path "*/node_modules/*" -not -path "*/.venv/*" -not -path "*/dist/*" -not -path "*/__pycache__/*" -printf '%h\n' | sort -u)

if [[ ${#BATCHES[@]} -eq 0 ]]; then
    echo "No $LANG source files found in $SRC_DIR" >&2
    exit 0
fi

echo "Reviewing ${#BATCHES[@]} batches..."

for i in "${!BATCHES[@]}"; do
    batch_name="${BATCH_NAMES[$i]}"
    echo "  [$((i+1))/${#BATCHES[@]}] $batch_name..."

    echo "## Batch $((i+1)): $batch_name" >> "$OUTPUT"
    echo "" >> "$OUTPUT"

    full_prompt="$REVIEW_PROMPT

--- CODE TO REVIEW ---
${BATCHES[$i]}"

    response=$(curl -s --max-time 300 "$OLLAMA_URL/api/generate" \
        -d "$(jq -n --arg model "$MODEL" --arg prompt "$full_prompt" \
            '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.1, num_predict: 4096}}')" \
        2>&1)

    review=$(echo "$response" | jq -r '.response // "ERROR: No response"' 2>/dev/null)

    if [[ "$review" == "ERROR: No response" ]] || [[ -z "$review" ]]; then
        echo "**ERROR**: Failed to get review for this batch." >> "$OUTPUT"
        echo "Raw response: $response" >> "$OUTPUT"
    else
        echo "$review" >> "$OUTPUT"
    fi

    {
        echo ""
        echo "---"
        echo ""
    } >> "$OUTPUT"
done

echo ""
echo "Review complete: $OUTPUT"
echo "Batches: ${#BATCHES[@]} | Model: $MODEL | Language: $LANG"
