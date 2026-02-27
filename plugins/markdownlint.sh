#!/usr/bin/env bash
# Plugin: markdownlint — Markdown linting and style enforcement
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="markdownlint"
PLUGIN_DESC="Markdown linting and style enforcement"

detect() {
    local count
    count=$(count_files "*.md")
    [[ "$count" -ge 3 ]]
}

install() {
    if is_node; then
        npm_install_dev markdownlint-cli2
    elif cmd_exists npm; then
        npm install -g markdownlint-cli2 2>/dev/null || echo "  [info] Install: npm install -g markdownlint-cli2"
    else
        echo "  [info] Install markdownlint-cli2: npm install -g markdownlint-cli2"
    fi
}

configure() {
    copy_config ".markdownlint.json" ".markdownlint.json"

    if is_node; then
        add_make_target "lint-md" "npx markdownlint-cli2 '**/*.md' '#node_modules'"
        add_ci_step "Markdown lint" "npx markdownlint-cli2 '**/*.md' '#node_modules'"
    else
        add_make_target "lint-md" "markdownlint-cli2 '**/*.md'"
    fi
}
