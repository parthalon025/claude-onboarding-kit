#!/usr/bin/env bash
# Plugin: sonarcloud — SonarCloud quality gate (code smells, bugs, security hotspots)
PLUGIN_TIER="$TIER_ADVANCED"
PLUGIN_NAME="sonarcloud"
PLUGIN_DESC="SonarCloud quality gate -- code smells, bugs, security hotspots"

detect() {
    has_gha
}

install() {
    # SonarCloud runs in CI only
    echo "SonarCloud runs in GitHub Actions — no local install needed"
    echo "  [info] Requires SONAR_TOKEN secret in GitHub repo settings"
}

configure() {
    local workflow_src="$KIT_DIR/linter-configs/sonarcloud.yml"
    local workflow_dst="${PROJECT_ROOT:-.}/.github/workflows/sonarcloud.yml"
    local props_src="$KIT_DIR/linter-configs/sonar-project.properties"
    local props_dst="${PROJECT_ROOT:-.}/sonar-project.properties"

    if [[ -f "$workflow_dst" ]]; then
        echo "  [exists] .github/workflows/sonarcloud.yml"
    elif [[ -f "$workflow_src" ]]; then
        mkdir -p "${PROJECT_ROOT:-.}/.github/workflows"
        cp "$workflow_src" "$workflow_dst"
        echo "  [+] .github/workflows/sonarcloud.yml"
    fi

    if [[ -f "$props_dst" ]]; then
        echo "  [exists] sonar-project.properties"
    elif [[ -f "$props_src" ]]; then
        cp "$props_src" "$props_dst"
        echo "  [+] sonar-project.properties (edit organization + project key)"
    fi
}
