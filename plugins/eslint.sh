#!/usr/bin/env bash
# Plugin: eslint — JavaScript/TypeScript linting with security and modularity plugins
PLUGIN_TIER="$TIER_CORE"
PLUGIN_NAME="eslint"
PLUGIN_DESC="JavaScript/TypeScript linting with security and modularity plugins"

detect() {
    is_node
}

install() {
    local deps=(eslint @eslint/js eslint-plugin-import eslint-plugin-security eslint-config-prettier)
    if is_typescript; then
        deps+=(@typescript-eslint/eslint-plugin @typescript-eslint/parser typescript-eslint)
    fi
    npm_install_dev "${deps[@]}"
}

configure() {
    copy_config "eslint.config.js" "eslint.config.js"

    local src_dir="src/"
    if [[ ! -d "${PROJECT_ROOT:-.}/src" ]]; then
        src_dir="."
    fi
    add_make_target "lint-js" "npx eslint ${src_dir}"
    add_make_lint_dep "lint-js"
    add_ci_step "ESLint" "npx eslint ${src_dir}"
}
