#!/usr/bin/env bash
# Plugin: megalinter — MegaLinter CI (50+ linters, copy-paste detection, spelling)
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="megalinter"
PLUGIN_DESC="MegaLinter CI -- 50+ linters, copy-paste detection, spelling"

detect() {
    has_gha
}

install() {
    # MegaLinter runs in CI via Docker — no local install needed
    echo "MegaLinter runs in GitHub Actions (Docker) — no local install needed"
    echo "  [info] For local runs: npx mega-linter-runner --flavor cupcake"
}

configure() {
    # MegaLinter config
    local config_src="$KIT_DIR/linter-configs/.mega-linter.yml"
    local config_dst="${PROJECT_ROOT:-.}/.mega-linter.yml"
    if [[ -f "$config_dst" ]]; then
        echo "  [exists] .mega-linter.yml"
    elif [[ -f "$config_src" ]]; then
        cp "$config_src" "$config_dst"
        echo "  [+] .mega-linter.yml"
    fi

    # MegaLinter CI workflow
    local workflow_src="$KIT_DIR/linter-configs/megalinter.yml"
    local workflow_dst="${PROJECT_ROOT:-.}/.github/workflows/megalinter.yml"
    if [[ -f "$workflow_dst" ]]; then
        echo "  [exists] .github/workflows/megalinter.yml"
    elif [[ -f "$workflow_src" ]]; then
        mkdir -p "${PROJECT_ROOT:-.}/.github/workflows"
        cp "$workflow_src" "$workflow_dst"
        echo "  [+] .github/workflows/megalinter.yml"
    fi

    gitignore_add "megalinter-reports/"
}
