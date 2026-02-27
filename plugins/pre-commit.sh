#!/usr/bin/env bash
# Plugin: pre-commit — Pre-commit framework for Python projects
PLUGIN_TIER="$TIER_RECOMMENDED"
PLUGIN_NAME="pre-commit"
PLUGIN_DESC="Pre-commit framework for multi-language git hook management"

detect() {
    is_python && ! is_node
}

install() {
    pip_install pre-commit
}

configure() {
    # Don't overwrite existing .pre-commit-config.yaml (gitleaks phase may have created one)
    if has_file ".pre-commit-config.yaml"; then
        echo "  [exists] .pre-commit-config.yaml — checking for ruff hooks"
        if ! grep -q "astral-sh/ruff-pre-commit" "${PROJECT_ROOT:-.}/.pre-commit-config.yaml" 2>/dev/null; then
            cat >> "${PROJECT_ROOT:-.}/.pre-commit-config.yaml" << 'EOF'
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.6
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
EOF
            echo "  [+] Added ruff hooks to .pre-commit-config.yaml"
        fi
    else
        cat > "${PROJECT_ROOT:-.}/.pre-commit-config.yaml" << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.6
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
EOF
        echo "  [+] .pre-commit-config.yaml"
    fi

    # Install hooks
    if cmd_exists pre-commit; then
        (cd "${PROJECT_ROOT:-.}" && pre-commit install 2>/dev/null) || true
        echo "  [+] pre-commit hooks installed"
    fi
}
