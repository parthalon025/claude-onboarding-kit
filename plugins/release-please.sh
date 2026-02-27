#!/usr/bin/env bash
# Plugin: release-please — Automated versioning and releases from conventional commits
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="release-please"
PLUGIN_DESC="Automated versioning and changelog from conventional commits"

detect() {
    has_gha
}

install() {
    # Release Please runs in CI only
    echo "Release Please runs in GitHub Actions — no local install needed"
    echo "  [info] Requires conventional commits (pair with commitlint plugin)"
}

configure() {
    local workflow_src="$KIT_DIR/linter-configs/release-please.yml"
    local workflow_dst="${PROJECT_ROOT:-.}/.github/workflows/release-please.yml"
    if [[ -f "$workflow_dst" ]]; then
        echo "  [exists] .github/workflows/release-please.yml"
        return
    fi
    if [[ -f "$workflow_src" ]]; then
        mkdir -p "${PROJECT_ROOT:-.}/.github/workflows"
        cp "$workflow_src" "$workflow_dst"
        echo "  [+] .github/workflows/release-please.yml"
    fi
}
