#!/usr/bin/env bash
# Plugin: lint-staged — Pre-commit: only lint staged files (Node projects)
PLUGIN_TIER="$TIER_RECOMMENDED"
PLUGIN_NAME="lint-staged"
PLUGIN_DESC="Pre-commit: only lint staged files (Node projects)"

detect() {
    is_node
}

install() {
    npm_install_dev lint-staged husky
}

configure() {
    # Initialize husky if not already set up
    if [[ ! -d "${PROJECT_ROOT:-.}/.husky" ]]; then
        (cd "${PROJECT_ROOT:-.}" && npx husky init 2>/dev/null || npx husky install 2>/dev/null || true)
        echo "  [+] Initialized husky"
    fi

    # Create pre-commit hook for lint-staged
    local husky_hook="${PROJECT_ROOT:-.}/.husky/pre-commit"
    if [[ ! -f "$husky_hook" ]] || ! grep -q "lint-staged" "$husky_hook" 2>/dev/null; then
        echo "npx lint-staged" >> "$husky_hook"
        chmod +x "$husky_hook"
        echo "  [+] .husky/pre-commit (lint-staged)"
    fi

    # Add lint-staged config to package.json if not present
    if ! grep -q '"lint-staged"' "${PROJECT_ROOT:-.}/package.json" 2>/dev/null; then
        # Create a lint-staged config file instead
        local config_file="${PROJECT_ROOT:-.}/.lintstagedrc.json"
        if [[ ! -f "$config_file" ]]; then
            local config='{'
            config+='"*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"]'
            if is_typescript; then
                config+=','
                config+='"*.{json,md,yml,yaml}": ["prettier --write"]'
            fi
            config+='}'
            echo "$config" > "$config_file"
            echo "  [+] .lintstagedrc.json"
        fi
    fi
}
