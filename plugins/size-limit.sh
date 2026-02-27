#!/usr/bin/env bash
# Plugin: size-limit — Bundle size tracking for Node.js packages
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="size-limit"
PLUGIN_DESC="Bundle size tracking and budgets (Node.js)"

detect() {
    is_node && (has_file "src/index.ts" || has_file "src/index.js" || has_file "index.js")
}

install() {
    local deps=(size-limit @size-limit/preset-small-lib)
    if is_typescript; then
        deps+=(@size-limit/preset-app)
    fi
    npm_install_dev "${deps[@]}"
}

configure() {
    copy_config ".size-limit.json" ".size-limit.json"
    add_make_target "size" "npx size-limit"
    add_ci_step "Bundle size" "npx size-limit"
}
