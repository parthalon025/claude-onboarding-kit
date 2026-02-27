#!/usr/bin/env bash
# Plugin: actionlint — GitHub Actions workflow linting
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="actionlint"
PLUGIN_DESC="GitHub Actions workflow file linting"

detect() {
    has_gha && has_files "*.yml" && [[ -d "${PROJECT_ROOT:-.}/.github/workflows" ]]
}

install() {
    if cmd_exists actionlint; then
        echo "actionlint already installed"
        return
    fi
    if cmd_exists brew; then
        brew install actionlint
    elif cmd_exists go; then
        go install github.com/rhysd/actionlint/cmd/actionlint@latest
    else
        echo "  [info] Install actionlint: https://github.com/rhysd/actionlint#install"
    fi
}

configure() {
    add_make_target "lint-actions" "actionlint"
    add_make_lint_dep "lint-actions"
}
