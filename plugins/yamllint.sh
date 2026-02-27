#!/usr/bin/env bash
# Plugin: yamllint — YAML linting and validation
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="yamllint"
PLUGIN_DESC="YAML linting and validation"

detect() {
    local count
    count=$(count_files "*.yml")
    local count2
    count2=$(count_files "*.yaml")
    [[ $((count + count2)) -ge 3 ]]
}

install() {
    pip_install yamllint
}

configure() {
    copy_config ".yamllint" ".yamllint"
    add_make_target "lint-yaml" "yamllint ."
    add_make_lint_dep "lint-yaml"
    add_ci_step "YAML lint" "yamllint ."
}
