#!/usr/bin/env bash
# Plugin: commitlint — Conventional commit message enforcement
PLUGIN_TIER="$TIER_RECOMMENDED"
PLUGIN_NAME="commitlint"
PLUGIN_DESC="Conventional commit message enforcement"

detect() {
    has_git
}

install() {
    if is_node; then
        npm_install_dev "@commitlint/cli" "@commitlint/config-conventional"
    else
        echo "  [info] commitlint requires Node.js — install globally: npm install -g @commitlint/cli @commitlint/config-conventional"
    fi
}

configure() {
    copy_config "commitlint.config.js" "commitlint.config.js"

    # Set up commit-msg hook
    if is_node && npm_has_dep "husky"; then
        echo "  [info] Add commitlint to husky commit-msg hook:"
        echo "         npx husky add .husky/commit-msg 'npx commitlint --edit \$1'"
    elif has_file ".git/hooks/commit-msg"; then
        echo "  [exists] .git/hooks/commit-msg — add commitlint manually"
    else
        local hook_file="${PROJECT_ROOT:-.}/.git/hooks/commit-msg"
        if [[ -d "${PROJECT_ROOT:-.}/.git/hooks" ]]; then
            cat > "$hook_file" << 'HOOK'
#!/bin/bash
npx commitlint --edit "$1" 2>/dev/null || echo "[warn] commitlint not available — skipping"
HOOK
            chmod +x "$hook_file"
            echo "  [+] .git/hooks/commit-msg (commitlint)"
        fi
    fi
}
