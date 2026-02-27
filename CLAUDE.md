# claude-onboarding-kit

Bootstrap kit that scaffolds new projects with a full autonomous dev pipeline — CI/CD, security scanning, Claude Code web support, quality gates, local AI code review, semantic code search, and lessons tracking. Run `install.sh` once, then `/setup-repo` in any project.

## Commands

```bash
bash install.sh          # Install kit to ~/.claude/kit/ and scripts to ~/.local/bin/
bash uninstall.sh        # Remove all installed files
claude-init [node|python|general] [--product|--lib]   # Quick scaffold (no interactive pipeline)
/setup-repo              # Full interactive pipeline (14-phase skill)
lint-install [--dry-run] [--only core|recommended|all] [--skip PLUGIN] [--project-root DIR]
ollama-code-review [--lang LANG] [--model MODEL] [--src-dir DIR] [--output FILE] <dir>
generate-embeddings [--src-dir DIR] [--model MODEL] [--output DIR]
lessons-db scan --staged-only   # Anti-pattern scanner (replaces lesson-check)
bash tests/validate.sh   # Validate kit structure
```

## Skills (invoke in Claude Code with the Skill tool)

| Skill | When |
|-------|------|
| `/setup-repo` | Full 14-phase interactive project setup |
| `/create-tech-spec` | Architecture contract before implementation |
| `/create-risk-log` | Risk scoring before writing code |
| `/create-qa-plan` | Acceptance criteria test matrix |
| `/create-adr` | Document a non-obvious technical decision |
| `/create-retrospective` | Project close-out + lesson capture |
| `/create-mrd` | Market requirements (product/lib modes) |
| `/create-roadmap` | Milestone planning |
| `/create-release-plan` | Launch checklist + rollback plan |

## Architecture

- `install.sh` / `uninstall.sh` — install/remove the kit system-wide
- `bin/claude-init` — canonical bootstrap script; `install.sh` symlinks `~/.local/bin/claude-init` here
- `scripts/` — installable scripts: `lint-install.sh`, `ollama-code-review.sh`, `generate-embeddings.sh`
- `_archived/lesson-check.sh` — deprecated; use `lessons-db scan --staged-only` instead
- `skills/setup-repo/SKILL.md` — the `/setup-repo` Claude skill (14-phase pipeline)
- `skills/create-*/SKILL.md` — 8 lifecycle skills (tech-spec, risk-log, qa-plan, adr, retrospective, mrd, roadmap, release-plan)
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

`/setup-repo` is the primary interface — a Claude skill that runs a 14-phase interactive pipeline: gather info → scaffold → GitHub settings → gitleaks → code quality → session hook → CI workflows → quality gates (lessons-db) → ollama review → embeddings → mode-based dirs → draft artifacts → supporting files → security gate → verification.

`claude-init` is a lighter alternative: git init, GitHub repo creation, CLAUDE.md template, hookify rules — no interactive prompts.

`KIT_DIR` for scripts is derived from the install location — edit source files here, not in `~/.claude/kit/`.

## Conventions

- `~/.local/bin/claude-init` is a symlink to `bin/claude-init` — always edit `bin/claude-init`
- Hookify rules use `hookify.*.local.md` naming (git-ignored in target projects)
- Templates use `{{PLACEHOLDER}}` tokens replaced by `sed` at init time
- Plugin files declare their tier in a `TIER=` variable; `lib.sh` is shared library, not a plugin
- All scripts are idempotent — safe to re-run on an existing project
