#!/usr/bin/env bash
# Claude Code Project Initializer
# Usage: claude-init [node|python|general]
#
# Bootstraps a project with:
#   Phase 1: Git + GitHub repo creation
#   Phase 2: CLAUDE.md from template
#   Phase 3: Hookify safety rules
#   Phase 4: .gitignore updates
#   Phase 5: Validation summary
#
# Idempotent — safe to re-run on existing projects.
set -euo pipefail

PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
KIT_DIR="${CLAUDE_KIT_DIR:-$HOME/.claude/kit}"
CONFIG_FILE="$KIT_DIR/config.env"
TEMPLATE_TYPE="${1:-}"

# Load config if available
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

GITHUB_ORG="${GITHUB_ORG:-}"
DEFAULT_VISIBILITY="${DEFAULT_VISIBILITY:-private}"

echo "=== Claude Code Project Init ==="
echo "Project: $PROJECT_NAME"
echo "Directory: $PROJECT_DIR"
echo ""

# --- Phase 1: Git + GitHub ---

if [[ ! -d "$PROJECT_DIR/.git" ]]; then
    git init
    echo "[+] Initialized git repository"
else
    echo "[=] Git already initialized"
fi

REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
if [[ -z "$REMOTE_URL" ]]; then
    if [[ -n "$GITHUB_ORG" ]] && command -v gh &>/dev/null; then
        gh repo create "$GITHUB_ORG/$PROJECT_NAME" --"$DEFAULT_VISIBILITY" --source=. --push
        echo "[+] Created GitHub repo: $GITHUB_ORG/$PROJECT_NAME"
    else
        echo "[!] No remote configured. Set GITHUB_ORG in config or run:"
        echo "    gh repo create <org>/$PROJECT_NAME --private --source=. --push"
    fi
else
    echo "[=] Remote already configured: $REMOTE_URL"
fi

# --- Phase 2: CLAUDE.md from template ---

if [[ -z "$TEMPLATE_TYPE" ]]; then
    if [[ -f "package.json" ]]; then
        TEMPLATE_TYPE="node"
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        TEMPLATE_TYPE="python"
    else
        TEMPLATE_TYPE="general"
    fi
    echo "Auto-detected project type: $TEMPLATE_TYPE"
fi

if [[ ! -f "$PROJECT_DIR/CLAUDE.md" ]]; then
    TEMPLATE="$KIT_DIR/templates/CLAUDE.md.$TEMPLATE_TYPE"
    if [[ -f "$TEMPLATE" ]]; then
        sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$TEMPLATE" > "$PROJECT_DIR/CLAUDE.md"
        echo "[+] Created CLAUDE.md from $TEMPLATE_TYPE template"
        echo "    Edit CLAUDE.md to fill in {{placeholders}}"
    else
        echo "[!] Template not found: $TEMPLATE"
        echo "    Run install.sh from claude-onboarding-kit to install templates"
    fi
else
    echo "[=] CLAUDE.md already exists, skipping"
fi

# --- Phase 3: Hookify rules ---

mkdir -p "$PROJECT_DIR/.claude"
RULES_COPIED=0
if [[ -d "$KIT_DIR/hookify-rules" ]]; then
    for rule in "$KIT_DIR/hookify-rules/"*.local.md; do
        [[ -f "$rule" ]] || continue
        RULE_NAME="$(basename "$rule")"
        if [[ ! -f "$PROJECT_DIR/.claude/$RULE_NAME" ]]; then
            cp "$rule" "$PROJECT_DIR/.claude/$RULE_NAME"
            RULES_COPIED=$((RULES_COPIED + 1))
        fi
    done
fi
echo "[+] Copied $RULES_COPIED hookify rules to .claude/"

# --- Phase 4: .gitignore ---

GITIGNORE="$PROJECT_DIR/.gitignore"
ENTRIES_ADDED=0

add_gitignore() {
    local entry="$1"
    if ! grep -qF "$entry" "$GITIGNORE" 2>/dev/null; then
        echo "$entry" >> "$GITIGNORE"
        ENTRIES_ADDED=$((ENTRIES_ADDED + 1))
    fi
}

if [[ -d "$PROJECT_DIR/.git" ]]; then
    # Ensure .gitignore exists
    touch "$GITIGNORE"

    # Claude Code local files
    if ! grep -q "claude.*local" "$GITIGNORE" 2>/dev/null; then
        echo "" >> "$GITIGNORE"
        echo "# Claude Code local files" >> "$GITIGNORE"
    fi
    add_gitignore "CLAUDE.local.md"
    add_gitignore ".claude/*.local.md"

    # Security
    add_gitignore ".env"
    add_gitignore ".env.*"
    add_gitignore "!.env.example"
    add_gitignore "client_secret*.json"

    # Embeddings
    add_gitignore ".embeddings/"

    echo "[+] Added $ENTRIES_ADDED entries to .gitignore"
fi

# --- Phase 5: Summary ---

echo ""
echo "=== Done ==="
echo ""
echo "Next steps:"
echo "  1. Edit CLAUDE.md — fill in {{placeholders}} with real values"
echo "  2. Run '/setup-repo' in Claude for full pipeline (CI, hooks, security, etc.)"
echo "  3. Review .claude/ hookify rules and disable any you don't want"
