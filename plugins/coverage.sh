#!/usr/bin/env bash
# Plugin: coverage — Test coverage thresholds
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="coverage"
PLUGIN_DESC="Test coverage threshold enforcement"

detect() {
    (is_node && has_tests_node) || (is_python && has_tests_python)
}

install() {
    if is_node; then
        # Most Node test runners have built-in coverage (vitest, jest)
        echo "  [info] Coverage is typically built into your test runner (vitest, jest, c8)"
    elif is_python; then
        pip_install coverage pytest-cov
    fi
}

configure() {
    if is_python; then
        add_make_target "coverage" "pytest --cov=src --cov-report=term-missing --cov-fail-under=80"
        add_ci_step "Coverage" "pytest --cov=src --cov-report=term-missing --cov-fail-under=80"
    elif is_node; then
        # Detect test runner
        if npm_has_dep "vitest"; then
            add_make_target "coverage" "npx vitest run --coverage"
            add_ci_step "Coverage" "npx vitest run --coverage"
        elif npm_has_dep "jest"; then
            add_make_target "coverage" "npx jest --coverage --coverageThreshold='{\"global\":{\"lines\":80}}'"
            add_ci_step "Coverage" "npx jest --coverage"
        else
            add_make_target "coverage" "npx c8 npm test"
            echo "  [info] Configure coverage threshold in package.json or c8 config"
        fi
    fi
    gitignore_add "coverage/"
}
