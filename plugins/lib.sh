#!/usr/bin/env bash
# Shared library for lint-install plugins
# Provides detection helpers, installation helpers, config management,
# and Makefile/CI workflow generation.

# Tier constants
TIER_CORE="core"
TIER_RECOMMENDED="recommended"
TIER_ADVANCED="advanced"

# Accumulated state (populated by plugins)
declare -a MAKE_TARGETS=()
declare -a MAKE_LINT_DEPS=()
declare -a MAKE_FORMAT_DEPS=()
declare -a CI_STEPS=()
declare -a INSTALLED_PLUGINS=()
declare -a SKIPPED_PLUGINS=()

# --- Project detection helpers ---

has_file() { [[ -f "${PROJECT_ROOT:-.}/$1" ]]; }
has_dir() { [[ -d "${PROJECT_ROOT:-.}/$1" ]]; }

has_files() {
    local pattern="$1"
    local result
    result=$(find "${PROJECT_ROOT:-.}" -name "$pattern" \
        -not -path "*/node_modules/*" \
        -not -path "*/.venv/*" \
        -not -path "*/vendor/*" \
        -not -path "*/.git/*" \
        -print -quit 2>/dev/null)
    [[ -n "$result" ]]
}

count_files() {
    find "${PROJECT_ROOT:-.}" -name "$1" \
        -not -path "*/node_modules/*" \
        -not -path "*/.venv/*" \
        -not -path "*/vendor/*" \
        -not -path "*/.git/*" 2>/dev/null | wc -l
}

is_node() { has_file "package.json"; }
is_typescript() { has_file "tsconfig.json"; }
is_python() { has_file "pyproject.toml" || has_file "setup.py" || has_file "setup.cfg"; }
has_docker() { has_file "Dockerfile" || has_files "Dockerfile.*"; }
has_gha() { has_dir ".github/workflows" || has_dir ".github"; }
has_tests_node() { has_dir "tests" || has_dir "__tests__" || has_dir "test" || grep -q '"test"' "${PROJECT_ROOT:-.}/package.json" 2>/dev/null; }
has_tests_python() { has_dir "tests" || has_dir "test" || has_files "test_*.py"; }
has_git() { has_dir ".git"; }

# --- Installation helpers ---

npm_has_dep() {
    grep -qE "\"$1\"" "${PROJECT_ROOT:-.}/package.json" 2>/dev/null
}

pip_has_pkg() {
    pip show "$1" &>/dev/null 2>&1
}

cmd_exists() {
    command -v "$1" &>/dev/null
}

npm_install_dev() {
    local deps=("$@")
    local to_install=()
    for dep in "${deps[@]}"; do
        if ! npm_has_dep "$dep"; then
            to_install+=("$dep")
        fi
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        echo "  Installing: ${to_install[*]}"
        (cd "${PROJECT_ROOT:-.}" && npm install --save-dev "${to_install[@]}")
    fi
}

pip_install() {
    local deps=("$@")
    local to_install=()
    for dep in "${deps[@]}"; do
        if ! pip_has_pkg "$dep"; then
            to_install+=("$dep")
        fi
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        echo "  Installing: ${to_install[*]}"
        if command -v pipx &>/dev/null; then
            for d in "${to_install[@]}"; do pipx install "$d"; done
        else
            pip install "${to_install[@]}"
        fi
    fi
}

# --- Config helpers ---

copy_config() {
    local src="${KIT_DIR:?KIT_DIR not set}/linter-configs/$1"
    local dst="${PROJECT_ROOT:-.}/$2"
    if [[ -f "$dst" ]]; then
        echo "  [exists] $2"
        return 0
    fi
    if [[ ! -f "$src" ]]; then
        echo "  [warn] Template not found: $1"
        return 1
    fi
    local dir
    dir=$(dirname "$dst")
    [[ -d "$dir" ]] || mkdir -p "$dir"
    cp "$src" "$dst"
    echo "  [+] $2"
    return 0
}

# Replace a placeholder in a file
fill_placeholder() {
    local file="$1" key="$2" value="$3"
    if [[ -f "$file" ]]; then
        sed -i "s|{{${key}}}|${value}|g" "$file"
    fi
}

# Ensure a line exists in a file (append if missing)
ensure_line() {
    local file="$1" line="$2"
    if [[ ! -f "$file" ]]; then
        echo "$line" > "$file"
    elif ! grep -qF "$line" "$file"; then
        echo "$line" >> "$file"
    fi
}

# Add entry to .gitignore if missing
gitignore_add() {
    ensure_line "${PROJECT_ROOT:-.}/.gitignore" "$1"
}

# --- Makefile accumulator ---

add_make_target() {
    local name="$1" command="$2"
    MAKE_TARGETS+=("${name}|${command}")
}

add_make_lint_dep() {
    MAKE_LINT_DEPS+=("$1")
}

add_make_format_dep() {
    MAKE_FORMAT_DEPS+=("$1")
}

generate_makefile() {
    local makefile="${PROJECT_ROOT:-.}/Makefile"
    if [[ -f "$makefile" ]]; then
        echo "[exists] Makefile — not overwriting (add targets manually)"
        return
    fi

    {
        echo ".PHONY: lint format ${MAKE_LINT_DEPS[*]} ${MAKE_FORMAT_DEPS[*]}"
        echo ""

        # Default target
        echo "all: lint"
        echo ""

        # Lint meta-target
        if [[ ${#MAKE_LINT_DEPS[@]} -gt 0 ]]; then
            echo "lint: ${MAKE_LINT_DEPS[*]}"
        else
            echo "lint:"
            echo "	@echo \"No lint targets configured\""
        fi
        echo ""

        # Format meta-target
        if [[ ${#MAKE_FORMAT_DEPS[@]} -gt 0 ]]; then
            echo "format: ${MAKE_FORMAT_DEPS[*]}"
        else
            echo "format:"
            echo "	@echo \"No format targets configured\""
        fi
        echo ""

        # Individual targets
        for entry in "${MAKE_TARGETS[@]}"; do
            local name="${entry%%|*}"
            local cmd="${entry#*|}"
            echo "${name}:"
            echo "	${cmd}"
            echo ""
        done
    } > "$makefile"
    echo "[+] Generated Makefile with ${#MAKE_TARGETS[@]} targets"
}

# --- CI workflow accumulator ---

add_ci_step() {
    local name="$1" run="$2"
    CI_STEPS+=("${name}|${run}")
}

generate_ci_workflow() {
    local workflow_dir="${PROJECT_ROOT:-.}/.github/workflows"
    local workflow="${workflow_dir}/lint.yml"
    if [[ -f "$workflow" ]]; then
        echo "[exists] .github/workflows/lint.yml — not overwriting"
        return
    fi
    if [[ ${#CI_STEPS[@]} -eq 0 ]]; then
        echo "[skip] No CI steps — skipping lint.yml generation"
        return
    fi

    mkdir -p "$workflow_dir"
    {
        cat <<'HEADER'
name: Lint

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
HEADER

        # Add setup steps based on project type
        if is_node; then
            cat <<'NODE'
      - uses: actions/setup-node@v4
        with:
          node-version: 'lts/*'
          cache: 'npm'
      - run: npm ci
NODE
        fi

        if is_python; then
            cat <<'PYTHON'
      - uses: actions/setup-python@v5
        with:
          python-version: '3.x'
      - run: pip install -e ".[dev]" 2>/dev/null || pip install -r requirements-dev.txt 2>/dev/null || true
PYTHON
        fi

        # Add lint steps from plugins
        for entry in "${CI_STEPS[@]}"; do
            local name="${entry%%|*}"
            local run="${entry#*|}"
            echo "      - name: ${name}"
            echo "        run: ${run}"
        done

    } > "$workflow"
    echo "[+] Generated .github/workflows/lint.yml with ${#CI_STEPS[@]} steps"
}

# --- Plugin registration ---

register_plugin() {
    INSTALLED_PLUGINS+=("$1")
}

register_skip() {
    SKIPPED_PLUGINS+=("$1")
}

# --- Summary ---

print_summary() {
    echo ""
    echo "=== Code Quality Summary ==="
    echo ""
    if [[ ${#INSTALLED_PLUGINS[@]} -gt 0 ]]; then
        echo "Installed (${#INSTALLED_PLUGINS[@]}):"
        for p in "${INSTALLED_PLUGINS[@]}"; do
            echo "  [ok] $p"
        done
    fi
    echo ""
    if [[ ${#SKIPPED_PLUGINS[@]} -gt 0 ]]; then
        echo "Skipped (${#SKIPPED_PLUGINS[@]}):"
        for p in "${SKIPPED_PLUGINS[@]}"; do
            echo "  [--] $p"
        done
    fi
    echo ""
}
