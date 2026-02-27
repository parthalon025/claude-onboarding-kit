#!/usr/bin/env bash
# Plugin: vulture — Dead code detection for Python
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="vulture"
PLUGIN_DESC="Dead code detection for Python"

detect() {
    is_python && has_files "*.py"
}

install() {
    pip_install vulture
}

configure() {
    local src_dir="src"
    if [[ ! -d "${PROJECT_ROOT:-.}/src" ]]; then
        src_dir="."
    fi
    add_make_target "deadcode" "vulture ${src_dir} --min-confidence 80"
    add_ci_step "Dead code (vulture)" "vulture ${src_dir} --min-confidence 80"
}
