#!/usr/bin/env bash
# Plugin: knip — Dead code detection for JavaScript/TypeScript
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="knip"
PLUGIN_DESC="Dead code and unused dependency detection (JS/TS)"

detect() {
    is_node
}

install() {
    npm_install_dev knip
}

configure() {
    copy_config "knip.json" "knip.json"
    add_make_target "deadcode" "npx knip"
    add_ci_step "Dead code (knip)" "npx knip"
}
