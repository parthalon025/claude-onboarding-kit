#!/usr/bin/env bash
# Plugin: codeql — GitHub CodeQL SAST (AST-level security scanning)
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="codeql"
PLUGIN_DESC="GitHub CodeQL SAST -- AST-level security scanning"

detect() {
    has_gha
}

install() {
    # CodeQL runs in CI only — no local install needed
    echo "CodeQL runs in GitHub Actions — no local install needed"
}

configure() {
    local lang="javascript-typescript"
    if is_python; then
        lang="python"
    fi

    local src="$KIT_DIR/linter-configs/codeql.yml"
    local dst="${PROJECT_ROOT:-.}/.github/workflows/codeql.yml"
    if [[ -f "$dst" ]]; then
        echo "  [exists] .github/workflows/codeql.yml"
        return
    fi
    mkdir -p "${PROJECT_ROOT:-.}/.github/workflows"
    if [[ -f "$src" ]]; then
        sed "s/{{LANGUAGE}}/$lang/g" "$src" > "$dst"
        echo "  [+] .github/workflows/codeql.yml (language: $lang)"
    else
        echo "  [warn] Template not found: codeql.yml"
    fi
}
