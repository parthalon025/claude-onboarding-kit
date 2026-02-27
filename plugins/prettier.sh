#!/usr/bin/env bash
# Plugin: prettier — Opinionated code formatter for JS/TS/JSON/CSS/MD
PLUGIN_TIER="$TIER_CORE"
PLUGIN_NAME="prettier"
PLUGIN_DESC="Opinionated code formatter for JS/TS/JSON/CSS/Markdown"

detect() {
    is_node
}

install() {
    npm_install_dev prettier
}

configure() {
    copy_config ".prettierrc" ".prettierrc"
    copy_config ".prettierignore" ".prettierignore"

    add_make_target "format-js" "npx prettier --write ."
    add_make_format_dep "format-js"
    add_make_target "format-check" "npx prettier --check ."
    add_ci_step "Prettier" "npx prettier --check ."
}
