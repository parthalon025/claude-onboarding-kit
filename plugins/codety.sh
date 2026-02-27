#!/usr/bin/env bash
# Plugin: codety — Codety Scanner (5000+ rules across 30+ languages)
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="codety"
PLUGIN_DESC="Codety Scanner -- 5000+ rules across 30+ languages"

detect() {
    has_gha
}

install() {
    # Codety runs in CI only via GitHub Action
    echo "Codety runs in GitHub Actions — no local install needed"
}

configure() {
    local src="$KIT_DIR/linter-configs/codety.yml"
    local dst="${PROJECT_ROOT:-.}/.github/workflows/codety.yml"
    if [[ -f "$dst" ]]; then
        echo "  [exists] .github/workflows/codety.yml"
        return
    fi
    if [[ -f "$src" ]]; then
        mkdir -p "${PROJECT_ROOT:-.}/.github/workflows"
        cp "$src" "$dst"
        echo "  [+] .github/workflows/codety.yml"
    fi
}
