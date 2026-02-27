#!/usr/bin/env bash
# Plugin: typescript — TypeScript type checking via tsc --noEmit
PLUGIN_TIER="$TIER_RECOMMENDED"
PLUGIN_NAME="typescript"
PLUGIN_DESC="TypeScript type checking via tsc --noEmit"

detect() {
    is_typescript
}

install() {
    npm_install_dev typescript
}

configure() {
    add_make_target "typecheck" "npx tsc --noEmit"
    add_make_lint_dep "typecheck"
    add_ci_step "TypeScript" "npx tsc --noEmit"
}
