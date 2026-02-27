#!/usr/bin/env bash
# Plugin: pip-audit — Python dependency vulnerability scanning
PLUGIN_TIER="$TIER_RECOMMENDED"
PLUGIN_NAME="pip-audit"
PLUGIN_DESC="Python dependency vulnerability scanning"

detect() {
    is_python
}

install() {
    pip_install pip-audit
}

configure() {
    add_make_target "audit" "pip-audit"
    add_ci_step "pip-audit" "pip-audit"
}
