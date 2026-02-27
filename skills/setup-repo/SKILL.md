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
5. **Project mode** — what kind of project is this?
   - `internal` — Internal tool, personal automation, scripts (default)
   - `product` — User-facing product with external users
   - `lib` — Open source library or framework meant for others to consume

   This determines which lifecycle artifacts are created, which directories are
   scaffolded, and which workflow pipeline is documented in CLAUDE.md.

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

**Before proceeding:** Present a summary table of all gathered values (including `PROJECT_MODE`) and ask for confirmation.

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
- Before PRs: `lessons-db scan --target . --baseline HEAD` (anti-pattern scanner)

## Lessons

- Check before planning: `/check-lessons` (surfaces relevant past mistakes)
- Capture after bugs: `/capture-lesson` (enforces template + validation)
- Lessons location: `docs/lessons/`
```

### Create directory structure:

```bash
mkdir -p docs/lessons docs/plans tasks
touch tasks/progress.txt  # append-only state file
```

### Wire lessons-db as git pre-commit hook:

```bash
cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
# Anti-pattern scanner — checks staged files against known bad patterns
LESSONS_DB="$(command -v lessons-db 2>/dev/null)"
if [ -x "$LESSONS_DB" ]; then
    $LESSONS_DB scan --target . --baseline HEAD 2>/dev/null || true
fi
HOOK
chmod +x .git/hooks/pre-commit
```

Note: This supplements (doesn't replace) the gitleaks pre-commit hook from Phase 4. If using `pre-commit` framework, both hooks coexist.

### Surface relevant lessons at setup time:

Run a targeted search based on project type and surface top matches into the CLAUDE.md `## Lessons` section:

```bash
if command -v lessons-db &>/dev/null; then
    case "$PROJECT_TYPE" in
        python) QUERY="python async error handling sqlite context manager" ;;
        node)   QUERY="typescript node async promise error handling" ;;
        *)      QUERY="error handling logging fallback silent failure" ;;
    esac
    echo "" >> CLAUDE.md
    echo "## Top Lessons for This Project" >> CLAUDE.md
    echo "" >> CLAUDE.md
    lessons-db search "$QUERY" --top 5 --format brief >> CLAUDE.md 2>/dev/null || true
fi
```

### Run scope inference:

```bash
if command -v scope-infer &>/dev/null; then
    scope-infer --project-root . --update-claude-md
fi
```

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

## Phase 10: Mode-Based Directory Structure

Create directories based on `$PROJECT_MODE`:

```bash
# All modes
mkdir -p docs/plans docs/decisions tasks
touch tasks/progress.txt

# Internal tool and above
mkdir -p docs/product

# Product and OSS Library
if [[ "$PROJECT_MODE" != "internal" ]]; then
    mkdir -p docs/research docs/design
fi
```

Create `tasks/pipeline-status.md` from the installed kit template:

```bash
KIT_DIR="${CLAUDE_KIT_DIR:-$HOME/.claude/kit}"
STATUS_TEMPLATE="$KIT_DIR/templates/pipeline-status-${PROJECT_MODE}.md"
[[ -f "$STATUS_TEMPLATE" ]] || STATUS_TEMPLATE="$KIT_DIR/templates/pipeline-status-internal.md"
sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s/{{KIT_VERSION}}/$(cat "$KIT_DIR/VERSION" 2>/dev/null || echo unknown)/g" \
    "$STATUS_TEMPLATE" > tasks/pipeline-status.md
```

---

## Phase 11: Draft Lifecycle Artifacts

Using the project description from Phase 1, generate draft content for
core artifacts — user edits rather than starting from scratch.

**All modes:** Draft skeleton PRD using `/create-prd` with the description.

**Product + OSS:** Also draft:
- MRD skeleton (`/create-mrd`) — market context, target users, KPIs
- Risk log (`/create-risk-log`) — 3-5 likely risks given project type
- Roadmap skeleton (`/create-roadmap`) — 3 milestone rows

**Do not ask the user to fill these in now** — scaffold and move on.
Remind them in Phase 14 next steps.

---

## Phase 12: Supporting Files

Copy template files from the kit:

```bash
KIT_DIR="${CLAUDE_KIT_DIR:-$HOME/.claude/kit}"

# AGENTS.md — multi-agent workflow documentation
cp "$KIT_DIR/templates/AGENTS.md" AGENTS.md
sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" AGENTS.md

# gitleaks allowlist for test credentials
cp "$KIT_DIR/gitleaks.toml" gitleaks.toml
sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" gitleaks.toml
```

Verify `.gitignore` includes:
- `.env`, `.env.*`, `!.env.example`
- `.claude/*.local.md`
- `client_secret*.json`
- `.embeddings/`

---

## Phase 13: Security Review (Pre-Publish Gate)

**Only run if user requests `--publish` or explicitly asks to go public.**

```bash
# Run security-reviewer agent across the repo
# This must pass before: gh repo edit --visibility public
```

Ask Claude Code to invoke the `security-reviewer` agent:
- Scans for hardcoded values, private hostnames, personal identifiers, API key patterns
- Output saved to `docs/security-review-$(date +%Y-%m-%d).md`
- Must show zero findings before flipping visibility

---

## Phase 14: Verification + Summary

Run all checks and present results as a table:

```text
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
[ok/!!] Pipeline status file created (tasks/pipeline-status.md)
[ok/!!] AGENTS.md created
[ok/!!] gitleaks.toml created
[ok/!!] Mode-based directories created ($PROJECT_MODE)
```

### Next steps (tell the user):

1. Fill in `{{placeholders}}` in CLAUDE.md and `AGENTS.md`
2. Merge session-start hook to default branch for web sessions
3. Run `bash scripts/generate-embeddings.sh` to build initial search index
4. Check `tasks/pipeline-status.md` — draft artifacts are ready to fill in
5. Run `claude` and start building

### Commit:

Stage all new files and make a commit:

```bash
git add -A
git commit -m "setup: full dev pipeline via /setup-repo"
```

Push to the current branch.
