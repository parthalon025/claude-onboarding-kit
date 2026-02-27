#!/usr/bin/env bash
# Plugin: cspell — Spell checking for code and documentation
PLUGIN_TIER="$TIER_RECOMMENDED"
PLUGIN_NAME="cspell"
PLUGIN_DESC="Spell checking for code and documentation"

detect() {
    # Useful for any project with code or docs
    return 0
}

install() {
    if is_node; then
        npm_install_dev cspell
    elif cmd_exists npm; then
        npm install -g cspell 2>/dev/null || echo "  [info] Install cspell: npm install -g cspell"
    else
        echo "  [info] Install cspell: npm install -g cspell (requires Node.js)"
    fi
}

configure() {
    copy_config "cspell.json" "cspell.json"

    if is_node; then
        add_make_target "spell" "npx cspell '**/*.{ts,tsx,js,jsx,md,py,sh}'"
        add_ci_step "Spell check" "npx cspell '**/*.{ts,tsx,js,jsx,md,py,sh}'"
    else
        add_make_target "spell" "cspell '**/*.{py,md,sh}'"
        add_ci_step "Spell check" "cspell '**/*.{py,md,sh}'"
    fi
}
