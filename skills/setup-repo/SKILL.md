---
name: setup-repo
description: Full GitHub repo setup with autonomous dev pipeline — scaffold, CI/CD, security, session hooks, quality gates, ollama code review, lessons DB, semantic embeddings. Use when creating a new project or retrofitting an existing one.
disable-model-invocation: true
---

# Setup Repository — Full Autonomous Dev Pipeline

Set up a complete, production-ready GitHub repository with CI/CD, security hardening, Claude Code web support, quality gates, ollama code review, lessons DB, and semantic embeddings.

Wraps `claude-init` and extends with everything needed for a fully autonomous dev pipeline.

All resources are bundled in `~/.claude/kit/` (installed by `install.sh` from `claude-onboarding-kit`).

## Arguments

$ARGUMENTS — optional: project name, type, or path (e.g., "my-project python" or just "node")

## Phase 0: Pre-flight Check

Verify the kit is installed:

```bash
KIT_DIR="${CLAUDE_KIT_DIR:-$HOME/.claude/kit}"
if [[ ! -d "$KIT_DIR/templates" ]]; then
    echo "ERROR: claude-onboarding-kit not installed."
    echo "Clone the repo and run install.sh first."
    exit 1
fi
```

Load configuration:
```bash
source "$KIT_DIR/config.env"
```

Read `GITHUB_ORG`, `DEFAULT_VISIBILITY`, `OLLAMA_URL`, and other settings from config.

---

## Phase 1: Gather Information

Ask the user for missing information. Auto-detect what you can from the filesystem.

**Required inputs:**

1. **Project name** — default: `basename` of current directory
2. **Project type** — auto-detect: `package.json` → node, `pyproject.toml` → python. Ask if ambiguous.
3. **Description** — one-line summary (used for GitHub repo description and README)
4. **Visibility** — private (default from config) or public

**Optional inputs (ask as a group):**

5. **Topics** — comma-separated GitHub topics (default: auto-generate from type, e.g., "typescript,nodejs")
6. **Homepage URL** — if applicable (default: none)
7. **Feature toggles** — which optional features to enable:
   - Branch protection on main (default: **no** — solo dev, opt-in)
   - Session-start hook for Claude Code web (default: **yes**)
   - Gitleaks pre-commit hook (default: **yes**)
   - Release workflow (default: **yes**)
   - Ollama code review integration (default: **yes**)
   - Lessons DB integration (default: **yes**)
   - Semantic code embeddings (default: **yes**)

If `$ARGUMENTS` provides values, parse them and skip redundant questions.

**Before proceeding:** Present a summary table of all gathered values and ask for confirmation.

---

## Phase 2: Scaffold

Delegates to `claude-init`. Three scenarios:

### New project (no directory or no git)

```bash
# If template repos are configured:
gh repo create $GITHUB_ORG/$NAME --template $GITHUB_ORG/template-$TYPE --$VISIBILITY --clone
cd $NAME && claude-init
```

### Existing directory (no repo)

```bash
cd $EXISTING_DIR && claude-init
```

`claude-init` handles: git init, `gh repo create --$VISIBILITY --source=. --push`, CLAUDE.md template, hookify rules.

### Already set up (re-run)

`claude-init` skips completed steps (idempotent). Proceed to Phase 3.

**Fallback:** If `claude-init` is not on PATH, perform its steps inline:
1. `git init` if no `.git/`
2. `gh repo create $GITHUB_ORG/$NAME --$VISIBILITY --source=. --push` if no remote
3. Copy CLAUDE.md template (node/python/general) from `$KIT_DIR/templates/`
4. Fill `{{PROJECT_NAME}}` placeholder
5. Copy hookify rules from `$KIT_DIR/hookify-rules/` to `.claude/`
6. Add `.claude/*.local.md` to `.gitignore`

---

## Phase 3: GitHub Repo Settings

Set metadata using the values from Phase 1:

```bash
gh repo edit --description "$DESCRIPTION"
gh repo edit --add-topic "$TOPIC1" --add-topic "$TOPIC2"
```

If homepage URL provided:
```bash
gh repo edit --homepage "$URL"
```

### Branch Protection (opt-in only)

If the user opted in to branch protection, use `--input -` with JSON (not `-f` flags — known issues with arrays):

```bash
echo '{
  "required_status_checks": {"strict": true, "contexts": ["lint-and-test"]},
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null
}' | gh api repos/$GITHUB_ORG/$NAME/branches/main/protection --method PUT --input -
```

All commands are idempotent — safe to re-run.

---

## Phase 4: Gitleaks Pre-Commit Hook

**Check first:** Does `.pre-commit-config.yaml` exist?

### If not — create it:

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks:
      - id: gitleaks
```

### If exists — check for gitleaks:

```bash
grep -q "gitleaks" .pre-commit-config.yaml
```

If missing, append the gitleaks repo entry to the existing file.

### Activate the hook:

```bash
pre-commit install
```

If `pre-commit` is not installed, inform the user: `pip install pre-commit && pre-commit install`

### Verify .gitignore:

Ensure these entries exist (add if missing):
- `.env`
- `.env.*`
- `!.env.example`
- `.claude/*.local.md`
- `client_secret*.json`

---

## Phase 4.5: Code Quality Toolkit

Auto-detect project content and install appropriate linters, formatters, type checkers, and CI integrations.

### Run lint-install:

```bash
lint-install --project-root .
```

If `lint-install` is not on PATH, use the kit path:

```bash
LINT_INSTALL="$(command -v lint-install 2>/dev/null || echo "$HOME/.local/bin/lint-install")"
if [ -x "$LINT_INSTALL" ]; then
    $LINT_INSTALL --project-root .
else
    echo "[warn] lint-install not found — run install.sh from claude-onboarding-kit"
fi
```

### What it does:

`lint-install` uses a plugin system that auto-detects project content:

| Tier | Plugins | Auto-detects |
|------|---------|-------------|
| **Core** | shellcheck, eslint, ruff, prettier, editorconfig | `*.sh`, `package.json`, `*.py`, all projects |
| **Recommended** | typescript, mypy, npm-audit, pip-audit, commitlint, lint-staged, pre-commit, cspell | `tsconfig.json`, Python, Node lock files, git repos |
| **Advanced** | actionlint, markdownlint, yamllint, hadolint, knip, vulture, size-limit, coverage, codeql, sonarcloud, codety, megalinter, release-please | `.github/`, `Dockerfile`, 3+ markdown/yaml files, test frameworks |

### Outputs:

1. **Makefile** with `lint`, `format`, and individual targets
2. **`.github/workflows/lint.yml`** with CI steps from detected plugins
3. **Config files** (`.shellcheckrc`, `eslint.config.js`, `ruff.toml`, `.prettierrc`, etc.)
4. **Advanced CI workflows** (CodeQL, SonarCloud, Codety, MegaLinter, Release Please)

### Options:

```bash
# Preview without installing
lint-install --dry-run --project-root .

# Only core tier
lint-install --only core --project-root .

# All tiers including advanced
lint-install --only all --project-root .

# Skip specific plugins
lint-install --skip megalinter,sonarcloud --project-root .
```

### Add to CLAUDE.md:

```markdown
## Code Quality

- Lint: `make lint` (runs all configured linters)
- Format: `make format` (runs all configured formatters)
- Individual: `make lint-js`, `make lint-py`, `make lint-sh`, etc.
- Reconfigure: `lint-install --project-root .`
```

---

## Phase 5: Session-Start Hook (Claude Code Web)

Copy the appropriate hook template from the kit:

### For Node projects:
```bash
mkdir -p .claude/hooks
cp "$KIT_DIR/hooks/session-start-node.sh" .claude/hooks/session-start.sh
chmod +x .claude/hooks/session-start.sh
```

### For Python projects:
```bash
mkdir -p .claude/hooks
cp "$KIT_DIR/hooks/session-start-python.sh" .claude/hooks/session-start.sh
chmod +x .claude/hooks/session-start.sh
```

### Register in `.claude/settings.json`:

If `.claude/settings.json` exists, merge the hooks config. If not, create:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

### Validate:

1. Run the hook directly: `CLAUDE_CODE_REMOTE=true ./.claude/hooks/session-start.sh`
2. Run linter on one file to confirm deps work
3. Run one test to confirm test framework works

---

## Phase 6: Enhanced CI Workflows

Copy workflow templates from the kit to `.github/workflows/`. Do NOT modify existing `ci.yml` or `dependabot.yml`.

```bash
mkdir -p .github/workflows
cp "$KIT_DIR/workflows/security.yml" .github/workflows/security.yml
cp "$KIT_DIR/workflows/release.yml" .github/workflows/release.yml
```

### `security.yml` — Gitleaks CI scan
Free for personal repos. No `GITLEAKS_LICENSE` needed.

### `release.yml` — GitHub Release on tag push
Requires `contents: write` permission. Uses `softprops/action-gh-release@v2`.

---

## Phase 7: Quality Gates + Lessons DB

### Add sections to the project's CLAUDE.md:

Append these sections to the existing CLAUDE.md (do not overwrite — add after existing content):

```markdown
## Quality Gates

- Before committing: `/verify` (self-verification checklist)
- Before PRs: `lesson-check --project-root .` (anti-pattern scanner)

## Lessons

- Check before planning: `/check-lessons` (surfaces relevant past mistakes)
- Capture after bugs: `/capture-lesson` (enforces template + validation)
- Lessons location: `docs/lessons/`
```

### Create directory structure:

```bash
mkdir -p docs/lessons docs/plans tasks
touch progress.txt  # append-only state file
```

### Wire lesson-check as git pre-commit hook:

```bash
cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
# Lesson anti-pattern scanner — checks staged files against known bad patterns
LESSON_CHECK="$(command -v lesson-check 2>/dev/null || echo "$HOME/.local/bin/lesson-check")"
if [ -x "$LESSON_CHECK" ]; then
    $LESSON_CHECK --project-root . --staged-only || exit 1
fi
HOOK
chmod +x .git/hooks/pre-commit
```

Note: This supplements (doesn't replace) the gitleaks pre-commit hook from Phase 4. If using `pre-commit` framework, both hooks coexist.

---

## Phase 8: Ollama Code Review

**Do NOT create a per-project script.** Reference the installed `ollama-code-review` command.

### Add to CLAUDE.md:

```markdown
## Local AI Review

- Code review: `ollama-code-review .` (uses local LLM)
- Embeddings: `generate-embeddings` (uses nomic-embed-text via ollama)
- Both commands installed by claude-onboarding-kit
- Configure model/URL in `~/.claude/kit/config.env`
```

### Check ollama availability:

```bash
if command -v ollama &>/dev/null || curl -s --max-time 2 "${OLLAMA_URL:-http://localhost:11434}/api/tags" > /dev/null 2>&1; then
    echo "[ok] Ollama available — code review and embeddings ready"
else
    echo "[!!] Ollama not available — code review and embeddings will be skipped"
    echo "     Install ollama or set OLLAMA_URL in ~/.claude/kit/config.env"
fi
```

---

## Phase 9: Semantic Code Embeddings

Create `scripts/generate-embeddings.sh` in the project that wraps the installed command:

```bash
#!/usr/bin/env bash
# Generate code embeddings — wrapper for installed generate-embeddings command
set -euo pipefail
GENERATE="$(command -v generate-embeddings 2>/dev/null || echo "$HOME/.local/bin/generate-embeddings")"
if [ -x "$GENERATE" ]; then
    exec "$GENERATE" "$@"
else
    echo "generate-embeddings not found. Install claude-onboarding-kit first."
    exit 1
fi
```

Make executable: `chmod +x scripts/generate-embeddings.sh`

### Add `.embeddings/` to `.gitignore`:

Ensure `.embeddings/` is listed in `.gitignore`.

### Add to CLAUDE.md:

```markdown
## Semantic Search

- Generate: `bash scripts/generate-embeddings.sh` (uses nomic-embed-text via ollama)
- Storage: `.embeddings/` (local, gitignored)
- Regenerate after major refactors or new modules
```

---

## Phase 10: Verification + Summary

Run all checks and present results as a table:

```
[ok/!!] Git initialized
[ok/!!] GitHub remote configured
[ok/!!] CLAUDE.md created
[ok/!!] Hookify rules installed (N rules)
[ok/!!] GitHub description/topics set
[ok/!!] Branch protection (enabled/skipped)
[ok/!!] Session-start hook created + validated
[ok/!!] Linter passes
[ok/!!] Tests pass
[ok/!!] Code quality toolkit installed (lint-install)
[ok/!!] Makefile generated with lint/format targets
[ok/!!] Gitleaks pre-commit installed
[ok/!!] CI workflows present (ci.yml, security.yml, release.yml, lint.yml)
[ok/!!] Quality gates + lessons documented in CLAUDE.md
[ok/!!] Ollama code review referenced in CLAUDE.md
[ok/!!] Embedding generation script installed
```

### Next steps (tell the user):

1. Fill in `{{placeholders}}` in CLAUDE.md
2. Merge session-start hook to default branch for web sessions
3. Run `bash scripts/generate-embeddings.sh` to build initial search index
4. Run `claude` and start building

### Commit:

Stage all new files and make a commit:

```bash
git add -A
git commit -m "setup: full dev pipeline via /setup-repo"
```

Push to the current branch.
