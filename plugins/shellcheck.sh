#!/usr/bin/env bash
# Plugin: shellcheck — Bash/shell script linting
PLUGIN_TIER="$TIER_CORE"
PLUGIN_NAME="shellcheck"
PLUGIN_DESC="Bash/shell script linting"

detect() {
    has_files "*.sh"
}

install() {
    if cmd_exists shellcheck; then
        echo "shellcheck already installed"
        return
    fi
    if cmd_exists apt-get; then
        sudo apt-get install -y shellcheck
    elif cmd_exists brew; then
        brew install shellcheck
    elif cmd_exists pacman; then
        sudo pacman -S --noconfirm shellcheck
    else
        echo "[warn] Install shellcheck manually: https://github.com/koalaman/shellcheck#installing"
    fi
}

configure() {
    copy_config ".shellcheckrc" ".shellcheckrc"
    add_make_target "lint-sh" "shellcheck \$\$(find . -name '*.sh' -not -path '*/node_modules/*' -not -path '*/.venv/*')"
    add_make_lint_dep "lint-sh"
    add_ci_step "ShellCheck" "shellcheck \$(find . -name '*.sh' -not -path '*/node_modules/*' -not -path '*/.venv/*')"
}
