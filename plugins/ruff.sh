#!/usr/bin/env bash
# Plugin: ruff — Python linting and formatting (replaces flake8, isort, pycodestyle, bandit)
PLUGIN_TIER="$TIER_CORE"
PLUGIN_NAME="ruff"
PLUGIN_DESC="Python linting + formatting with security rules (E,F,I,UP,B,S,SIM,C901,PLR)"

detect() {
    is_python || has_files "*.py"
}

install() {
    if cmd_exists ruff; then
        echo "ruff already installed"
        return
    fi
    pip_install ruff
}

configure() {
    # If pyproject.toml exists, check if ruff config is already there
    if has_file "pyproject.toml" && grep -q '\[tool\.ruff\]' "${PROJECT_ROOT:-.}/pyproject.toml" 2>/dev/null; then
        echo "  [exists] ruff config in pyproject.toml"
    else
        copy_config "ruff.toml" "ruff.toml"
    fi

    add_make_target "lint-py" "ruff check ."
    add_make_lint_dep "lint-py"
    add_make_target "format-py" "ruff format ."
    add_make_format_dep "format-py"
    add_ci_step "Ruff check" "ruff check ."
    add_ci_step "Ruff format" "ruff format --check ."
}
