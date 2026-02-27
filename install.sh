#!/usr/bin/env bash
# Install claude-onboarding-kit
# Copies skill, templates, hookify rules, scripts, and workflow templates
# to ~/.claude/ and ~/.local/bin/
set -euo pipefail

KIT_SOURCE="$(cd "$(dirname "$0")" && pwd)"
KIT_DEST="$HOME/.claude/kit"
SKILL_DEST="$HOME/.claude/skills/setup-repo"
BIN_DEST="$HOME/.local/bin"

echo "=== Installing claude-onboarding-kit ==="
echo ""

# --- Templates ---
mkdir -p "$KIT_DEST/templates"
cp "$KIT_SOURCE/templates/"* "$KIT_DEST/templates/"
echo "[+] Templates → $KIT_DEST/templates/"

# --- Hookify rules ---
mkdir -p "$KIT_DEST/hookify-rules"
cp "$KIT_SOURCE/hookify-rules/"* "$KIT_DEST/hookify-rules/"
echo "[+] Hookify rules → $KIT_DEST/hookify-rules/"

# --- Workflow templates ---
mkdir -p "$KIT_DEST/workflows"
cp "$KIT_SOURCE/workflows/"* "$KIT_DEST/workflows/"
echo "[+] Workflow templates → $KIT_DEST/workflows/"

# --- Hook templates ---
mkdir -p "$KIT_DEST/hooks"
cp "$KIT_SOURCE/hooks/"* "$KIT_DEST/hooks/"
echo "[+] Hook templates → $KIT_DEST/hooks/"

# --- Plugins ---
mkdir -p "$KIT_DEST/plugins"
cp "$KIT_SOURCE/plugins/"* "$KIT_DEST/plugins/"
echo "[+] Plugins → $KIT_DEST/plugins/"

# --- Linter configs ---
mkdir -p "$KIT_DEST/linter-configs"
cp "$KIT_SOURCE/linter-configs/"* "$KIT_DEST/linter-configs/"
echo "[+] Linter configs → $KIT_DEST/linter-configs/"

# --- Config (don't overwrite existing) ---
if [[ ! -f "$KIT_DEST/config.env" ]]; then
    cp "$KIT_SOURCE/config.env.example" "$KIT_DEST/config.env"
    echo "[+] Config → $KIT_DEST/config.env (edit this!)"
else
    echo "[=] Config already exists, skipping (check config.env.example for new options)"
fi

# --- Skill ---
mkdir -p "$SKILL_DEST"
cp "$KIT_SOURCE/skills/setup-repo/SKILL.md" "$SKILL_DEST/"
echo "[+] Skill → $SKILL_DEST/SKILL.md"

# --- Scripts ---
mkdir -p "$BIN_DEST"
for script in "$KIT_SOURCE/scripts/"*.sh; do
    name="$(basename "$script" .sh)"
    cp "$script" "$BIN_DEST/$name"
    chmod +x "$BIN_DEST/$name"
done
echo "[+] Scripts → $BIN_DEST/{claude-init,ollama-code-review,generate-embeddings,lesson-check,lint-install}"

# --- Verify PATH ---
if ! echo "$PATH" | grep -q "$BIN_DEST"; then
    echo ""
    echo "[!] $BIN_DEST is not in your PATH."
    echo "    Add to your shell profile:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
echo "=== Installed ==="
echo ""
echo "Next steps:"
echo "  1. Edit $KIT_DEST/config.env (set GITHUB_ORG at minimum)"
echo "  2. Run /setup-repo in any project to set up the full pipeline"
echo "  3. Or run 'claude-init' for quick scaffold without the interactive pipeline"
