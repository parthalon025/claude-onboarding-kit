#!/usr/bin/env bash
# Session-start hook for claude-onboarding-kit
# Surfaces kit version and validation status at session start

KIT_VERSION="$(cat "$(dirname "$0")/../VERSION" 2>/dev/null || echo unknown)"
echo ""
echo "=== claude-onboarding-kit v$KIT_VERSION ==="
echo "Run 'make test' to validate kit structure + shellcheck"
echo "Run 'bash install.sh' to reinstall after changes"
echo "================================================"
echo ""
