#!/usr/bin/env bash
# Generate code embeddings for semantic search using ollama
# Usage: generate-embeddings [options]
#
# Options:
#   --src-dir DIR     Source directories to scan (default: auto-detect)
#   --model MODEL     Ollama embedding model (default: from config or nomic-embed-text)
#   --output DIR      Output directory (default: .embeddings/)
#
# Requires: ollama running locally with the embedding model, curl, jq
set -euo pipefail

# --- Parse arguments ---
SRC_DIRS=""
MODEL=""
EMBEDDINGS_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --src-dir) SRC_DIRS="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        --output) EMBEDDINGS_DIR="$2"; shift 2 ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# --- Load config ---
KIT_CONFIG="${CLAUDE_KIT_DIR:-$HOME/.claude/kit}/config.env"
if [[ -f "$KIT_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$KIT_CONFIG"
fi

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
MODEL="${MODEL:-${OLLAMA_EMBED_MODEL:-nomic-embed-text}}"
EMBEDDINGS_DIR="${EMBEDDINGS_DIR:-.embeddings}"

# --- Check ollama is reachable ---
if ! curl -s --max-time 5 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "ERROR: Ollama not reachable at $OLLAMA_URL" >&2
    echo "Start ollama or set OLLAMA_URL in config" >&2
    exit 1
fi

mkdir -p "$EMBEDDINGS_DIR"

# --- Find source files ---
if [[ -z "$SRC_DIRS" ]]; then
    if [[ -f "package.json" ]]; then
        SRC_DIRS="src/ tests/"
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        SRC_DIRS="src/ tests/"
    else
        SRC_DIRS="."
    fi
fi

declare -a FILES=()
for dir in $SRC_DIRS; do
    [[ -d "$dir" ]] || continue
    if [[ -f "package.json" ]]; then
        while IFS= read -r f; do FILES+=("$f"); done < <(find "$dir" -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" 2>/dev/null | grep -v node_modules || true)
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        while IFS= read -r f; do FILES+=("$f"); done < <(find "$dir" -name "*.py" 2>/dev/null | grep -v __pycache__ || true)
    else
        while IFS= read -r f; do FILES+=("$f"); done < <(find "$dir" \( -name "*.py" -o -name "*.ts" -o -name "*.js" -o -name "*.go" -o -name "*.rs" \) 2>/dev/null || true)
    fi
done

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "No source files found to embed."
    exit 0
fi

TOTAL=${#FILES[@]}
echo "Generating embeddings for $TOTAL files using $MODEL..."

COUNT=0
ERRORS=0
for file in "${FILES[@]}"; do
    COUNT=$((COUNT + 1))
    CONTENT=$(head -200 "$file" 2>/dev/null || true)  # First 200 lines (context limit)
    HASH=$(echo "$file" | md5sum | cut -d' ' -f1)

    RESPONSE=$(curl -s --max-time 30 "$OLLAMA_URL/api/embed" \
        -d "$(jq -n --arg model "$MODEL" --arg input "$file: $CONTENT" \
            '{model: $model, input: $input}')" 2>&1)

    if echo "$RESPONSE" | jq -e '.embeddings' > /dev/null 2>&1; then
        # Store embedding with metadata
        jq -n --arg file "$file" --argjson response "$RESPONSE" \
            '{file: $file, embeddings: $response.embeddings}' \
            > "$EMBEDDINGS_DIR/$HASH.json"
    else
        ERRORS=$((ERRORS + 1))
    fi

    printf "\r  [%d/%d] %s" "$COUNT" "$TOTAL" "$file"
done

echo ""
echo "Embeddings saved to $EMBEDDINGS_DIR/"
echo "Files: $(find "$EMBEDDINGS_DIR" -name '*.json' 2>/dev/null | wc -l) | Errors: $ERRORS"
