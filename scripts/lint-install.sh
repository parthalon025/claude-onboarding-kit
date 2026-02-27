#!/usr/bin/env bash
# lint-install — Auto-detect project content and install appropriate code quality tools
# Part of claude-onboarding-kit
#
# Usage: lint-install [options] [--project-root DIR]
# Options:
#   --dry-run          Preview what would be installed without making changes
#   --only TIER        Only run: core, recommended, advanced, or all (default: core+recommended)
#   --skip PLUGIN      Skip specific plugin(s), comma-separated
#   --list             List available plugins and their tiers
#   --project-root DIR Target project directory (default: current directory)
set -euo pipefail

# --- Defaults ---
DRY_RUN="false"
TIER_FILTER="core,recommended"
SKIP_LIST=""
LIST_MODE="false"
PROJECT_ROOT="."
KIT_DIR="${CLAUDE_KIT_DIR:-$HOME/.claude/kit}"
PLUGIN_DIR="${KIT_DIR}/plugins"

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --only)
            TIER_FILTER="$2"
            shift 2
            ;;
        --skip)
            SKIP_LIST="$2"
            shift 2
            ;;
        --list)
            LIST_MODE="true"
            shift
            ;;
        --project-root)
            PROJECT_ROOT="$2"
            shift 2
            ;;
        -h|--help)
            sed -n '2,11p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Resolve to absolute path
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
export PROJECT_ROOT KIT_DIR DRY_RUN

# --- Verify kit is installed ---
if [[ ! -d "$PLUGIN_DIR" ]]; then
    echo "ERROR: Plugins not found at $PLUGIN_DIR"
    echo "Run install.sh from claude-onboarding-kit first."
    exit 1
fi

# --- Source shared library ---
# shellcheck source=../plugins/lib.sh
source "$PLUGIN_DIR/lib.sh"

# --- Build skip set ---
declare -A SKIP_SET
if [[ -n "$SKIP_LIST" ]]; then
    IFS=',' read -ra skip_arr <<< "$SKIP_LIST"
    for s in "${skip_arr[@]}"; do
        SKIP_SET["$s"]=1
    done
fi

# --- Check tier match ---
tier_matches() {
    local tier="$1"
    if [[ "$TIER_FILTER" == "all" ]]; then
        return 0
    fi
    [[ "$TIER_FILTER" == *"$tier"* ]]
}

# --- Read plugin metadata from file (grep-based, avoids sourcing) ---
read_plugin_tier() {
    local raw
    raw=$(grep -m1 '^PLUGIN_TIER=' "$1" 2>/dev/null)
    # Extract tier from formats like: PLUGIN_TIER="$TIER_CORE" or PLUGIN_TIER="core"
    if [[ "$raw" == *'TIER_CORE'* ]]; then echo "core"
    elif [[ "$raw" == *'TIER_RECOMMENDED'* ]]; then echo "recommended"
    elif [[ "$raw" == *'TIER_ADVANCED'* ]]; then echo "advanced"
    elif [[ "$raw" == *'"core"'* ]]; then echo "core"
    elif [[ "$raw" == *'"recommended"'* ]]; then echo "recommended"
    elif [[ "$raw" == *'"advanced"'* ]]; then echo "advanced"
    else echo "unknown"
    fi
}

read_plugin_desc() {
    grep -m1 '^PLUGIN_DESC=' "$1" 2>/dev/null | sed 's/^PLUGIN_DESC="//' | sed 's/"$//'
}

# --- Discover and sort plugins ---
declare -a CORE_PLUGINS=()
declare -a RECOMMENDED_PLUGINS=()
declare -a ADVANCED_PLUGINS=()

for plugin_file in "$PLUGIN_DIR"/*.sh; do
    [[ "$(basename "$plugin_file")" == "lib.sh" ]] && continue

    plugin_tier=$(read_plugin_tier "$plugin_file")

    case "$plugin_tier" in
        core)        CORE_PLUGINS+=("$plugin_file") ;;
        recommended) RECOMMENDED_PLUGINS+=("$plugin_file") ;;
        advanced)    ADVANCED_PLUGINS+=("$plugin_file") ;;
        *)           ADVANCED_PLUGINS+=("$plugin_file") ;;
    esac
done

ALL_PLUGINS=("${CORE_PLUGINS[@]}" "${RECOMMENDED_PLUGINS[@]}" "${ADVANCED_PLUGINS[@]}")

# --- List mode ---
if [[ "$LIST_MODE" == "true" ]]; then
    echo "Available plugins (${#ALL_PLUGINS[@]} total):"
    echo ""
    printf "  %-20s %-14s %s\n" "PLUGIN" "TIER" "DESCRIPTION"
    printf "  %-20s %-14s %s\n" "------" "----" "-----------"
    for plugin_file in "${ALL_PLUGINS[@]}"; do
        plugin_name="$(basename "$plugin_file" .sh)"
        p_tier=$(read_plugin_tier "$plugin_file")
        p_desc=$(read_plugin_desc "$plugin_file")
        printf "  %-20s %-14s %s\n" "$plugin_name" "${p_tier:-unknown}" "${p_desc:-}"
    done
    exit 0
fi

# --- Run plugins ---
echo "=== lint-install ==="
echo "Project: $PROJECT_ROOT"
echo "Tiers: $TIER_FILTER"
[[ -n "$SKIP_LIST" ]] && echo "Skipping: $SKIP_LIST"
[[ "$DRY_RUN" == "true" ]] && echo "Mode: DRY RUN (no changes)"
echo ""

for plugin_file in "${ALL_PLUGINS[@]}"; do
    plugin_name="$(basename "$plugin_file" .sh)"

    # Check skip list
    if [[ -n "${SKIP_SET[$plugin_name]+x}" ]]; then
        echo "[skip] $plugin_name (user-skipped)"
        register_skip "$plugin_name (user-skipped)"
        continue
    fi

    # Source plugin (brings in PLUGIN_TIER, PLUGIN_NAME, PLUGIN_DESC, detect, install, configure)
    unset -f detect install configure 2>/dev/null || true
    unset PLUGIN_TIER PLUGIN_NAME PLUGIN_DESC 2>/dev/null || true
    # shellcheck disable=SC1090
    source "$plugin_file"

    # Check tier filter
    if ! tier_matches "${PLUGIN_TIER:-advanced}"; then
        echo "[skip] $plugin_name (tier: ${PLUGIN_TIER:-unknown}, not in: $TIER_FILTER)"
        register_skip "$plugin_name (tier filtered)"
        continue
    fi

    # Run detection
    if detect 2>/dev/null; then
        echo "[match] $plugin_name — ${PLUGIN_DESC:-applies to this project}"
        if [[ "$DRY_RUN" != "true" ]]; then
            echo "  Installing $plugin_name..."
            install 2>&1 | sed 's/^/  /'
            configure 2>&1 | sed 's/^/  /'
            register_plugin "$plugin_name"
        else
            register_plugin "$plugin_name (dry-run)"
        fi
    else
        echo "[skip] $plugin_name — not applicable"
        register_skip "$plugin_name (not detected)"
    fi
done

# --- Generate outputs ---
echo ""
if [[ "$DRY_RUN" != "true" ]]; then
    generate_makefile
    generate_ci_workflow
fi

# --- Summary ---
print_summary

if [[ "$DRY_RUN" == "true" ]]; then
    echo "Dry run complete. Re-run without --dry-run to install."
fi
