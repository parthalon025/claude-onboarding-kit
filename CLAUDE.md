# claude-onboarding-kit

Bootstrap kit that scaffolds new projects with a full autonomous dev pipeline — CI/CD, security scanning, Claude Code web support, quality gates, local AI code review, semantic code search, and lessons tracking. Run `install.sh` once, then `/setup-repo` in any project.

## Commands

```bash
bash install.sh          # Install kit to ~/.claude/kit/ and scripts to ~/.local/bin/
bash uninstall.sh        # Remove all installed files
claude-init [node|python|general]   # Quick scaffold (no interactive pipeline)
/setup-repo              # Full interactive pipeline (10-phase skill)
lint-install [--dry-run] [--only core|recommended|all] [--skip PLUGIN] [--project-root DIR]
ollama-code-review [--lang LANG] [--model MODEL] [--src-dir DIR] [--output FILE] <dir>
generate-embeddings [--src-dir DIR] [--model MODEL] [--output DIR]
lesson-check [--project-root .] [--staged-only]
```

## Architecture

- `install.sh` / `uninstall.sh` — install/remove the kit system-wide
- `bin/claude-init` — legacy standalone quick-scaffold script (not installed by `install.sh`; use `scripts/claude-init.sh` instead)
- `scripts/` — all installable scripts: `claude-init.sh`, `lint-install.sh`, `ollama-code-review.sh`, `generate-embeddings.sh`, `lesson-check.sh`
- `skills/setup-repo/SKILL.md` — the `/setup-repo` Claude skill (10-phase pipeline)
- `templates/` — CLAUDE.md starters (`CLAUDE.md.node`, `CLAUDE.md.python`, `CLAUDE.md.general`) + `pull_request_template.md`
- `hookify-rules/` — 5 portable safety rules copied into new projects
- `plugins/` — 26 code quality plugins for `lint-install` (core / recommended / advanced tiers)
- `linter-configs/` — config file templates for linters and formatters
- `hooks/` — session-start hook templates (`session-start-node.sh`, `session-start-python.sh`)
- `workflows/` — CI workflow templates (`security.yml`, `release.yml`)
- `config.env.example` — configuration template (copied to `~/.claude/kit/config.env` by install)
- `docs/` — documentation

## How It Works

`install.sh` copies everything to `~/.claude/kit/` and installs scripts to `~/.local/bin/`.

`/setup-repo` is the primary interface — a Claude skill that runs a 10-phase interactive pipeline: gather info → scaffold → GitHub settings → gitleaks → code quality → session hook → CI workflows → quality gates → ollama review → verification.

`claude-init` is a lighter alternative: git init, GitHub repo creation, CLAUDE.md template, hookify rules — no interactive prompts.

`KIT_DIR` for scripts is derived from the install location — edit source files here, not in `~/.claude/kit/`.

## Conventions

- `~/.local/bin/claude-init` is installed from `scripts/claude-init.sh` by `install.sh` — edit `scripts/claude-init.sh`, not `bin/claude-init`
- Hookify rules use `hookify.*.local.md` naming (git-ignored in target projects)
- Templates use `{{PLACEHOLDER}}` tokens replaced by `sed` at init time
- Plugin files declare their tier in a `TIER=` variable; `lib.sh` is shared library, not a plugin
- All scripts are idempotent — safe to re-run on an existing project
