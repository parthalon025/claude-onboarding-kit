#!/usr/bin/env bash
# Plugin: hadolint — Dockerfile linting (best practices + security)
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="hadolint"
PLUGIN_DESC="Dockerfile linting for best practices and security"

detect() {
    has_docker
}

install() {
    if cmd_exists hadolint; then
        echo "hadolint already installed"
        return
    fi
    if cmd_exists brew; then
        brew install hadolint
    else
        echo "  [info] Install hadolint: https://github.com/hadolint/hadolint#install"
        echo "         Or use CI-only via hadolint/hadolint-action"
    fi
}

configure() {
    copy_config ".hadolint.yaml" ".hadolint.yaml"

    # Find all Dockerfiles
    local dockerfiles
    dockerfiles=$(find "${PROJECT_ROOT:-.}" -name "Dockerfile*" -not -path "*/.git/*" | head -5 | tr '\n' ' ')

    add_make_target "lint-docker" "hadolint ${dockerfiles}"
    add_make_lint_dep "lint-docker"
    add_ci_step "Hadolint" "hadolint ${dockerfiles}"
}
