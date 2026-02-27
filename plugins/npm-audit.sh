#!/usr/bin/env bash
# Plugin: npm-audit — Node.js dependency security scanning
PLUGIN_TIER="$TIER_RECOMMENDED"
PLUGIN_NAME="npm-audit"
PLUGIN_DESC="Node.js dependency vulnerability scanning"

detect() {
    is_node && has_file "package-lock.json"
}

install() {
    # Built into npm — no installation needed
    echo "npm audit is built into npm"
}

configure() {
    add_make_target "audit" "npm audit --audit-level=moderate"
    add_ci_step "npm audit" "npm audit --audit-level=moderate"
}
