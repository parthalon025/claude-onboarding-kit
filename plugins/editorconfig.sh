#!/usr/bin/env bash
# Plugin: editorconfig — Universal editor settings for consistent formatting
PLUGIN_TIER="$TIER_CORE"
PLUGIN_NAME="editorconfig"
PLUGIN_DESC="Universal editor settings for consistent formatting"

detect() {
    # Always applicable — every project benefits from consistent editor settings
    return 0
}

install() {
    # No installation needed — editors read .editorconfig natively
    echo "No installation needed (editors read .editorconfig natively)"
}

configure() {
    copy_config ".editorconfig" ".editorconfig"
}
