#!/usr/bin/env bash
# Plugin: mypy — Python static type checking
PLUGIN_TIER="$TIER_RECOMMENDED"
PLUGIN_NAME="mypy"
PLUGIN_DESC="Python static type checking"

detect() {
    is_python && has_files "*.py"
}

install() {
    pip_install mypy
}

configure() {
    # If pyproject.toml exists and has mypy config, skip
    if has_file "pyproject.toml" && grep -q '\[tool\.mypy\]' "${PROJECT_ROOT:-.}/pyproject.toml" 2>/dev/null; then
        echo "  [exists] mypy config in pyproject.toml"
    else
        copy_config "mypy-config.toml" "mypy-config.toml"
        echo "  [info] Merge mypy-config.toml into pyproject.toml [tool.mypy] section"
    fi

    local src_dir="src"
    if [[ ! -d "${PROJECT_ROOT:-.}/src" ]]; then
        src_dir="."
    fi
    add_make_target "typecheck" "mypy ${src_dir}"
    add_make_lint_dep "typecheck"
    add_ci_step "mypy" "mypy ${src_dir}"
}
