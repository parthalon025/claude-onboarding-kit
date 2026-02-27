#!/usr/bin/env bash
# Uninstall claude-onboarding-kit
# Removes installed files from ~/.claude/ and ~/.local/bin/
set -euo pipefail

KIT_DEST="$HOME/.claude/kit"
SKILL_DEST="$HOME/.claude/skills/setup-repo"
BIN_DEST="$HOME/.local/bin"

echo "=== Uninstalling claude-onboarding-kit ==="
echo ""

# --- Remove kit directory ---
if [[ -d "$KIT_DEST" ]]; then
    rm -rf "$KIT_DEST"
    echo "[x] Removed $KIT_DEST/"
fi

# --- Remove skill ---
if [[ -d "$SKILL_DEST" ]]; then
    rm -rf "$SKILL_DEST"
    echo "[x] Removed $SKILL_DEST/"
fi

# --- Remove scripts ---
SCRIPTS=(claude-init ollama-code-review generate-embeddings lesson-check lint-install)
for script in "${SCRIPTS[@]}"; do
    if [[ -f "$BIN_DEST/$script" ]] || [[ -L "$BIN_DEST/$script" ]]; then
        rm -f "$BIN_DEST/$script"
        echo "[x] Removed $BIN_DEST/$script"
    fi
done

echo ""
echo "=== Uninstalled ==="
echo "Note: Project files created by /setup-repo are NOT removed."
