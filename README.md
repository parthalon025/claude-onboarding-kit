# claude-onboarding-kit

Self-contained kit that bootstraps any new project with a full autonomous development pipeline — CI/CD, security scanning, Claude Code web support, quality gates, local AI code review, semantic code search, and lessons learned tracking. Run one command, get a production-ready repo.

## Quick Start

```bash
git clone https://github.com/parthalon025/claude-onboarding-kit.git
cd claude-onboarding-kit
cp config.env.example ~/.claude/kit/config.env  # or let install.sh do it
# Edit config.env: set GITHUB_ORG at minimum
bash install.sh
```

Then in any project:

```bash
# In Claude Code, run the skill:
/setup-repo

# Or for quick scaffold without the interactive pipeline:
claude-init
```

## What `/setup-repo` Sets Up

| Phase | What | Details |
|-------|------|---------|
| 1 | **Gather info** | Project name, type, description, visibility, **project mode** (internal/product/lib), feature toggles |
| 2 | **Scaffold** | Git init, GitHub repo, CLAUDE.md from template (with AI workflow discipline), hookify safety rules, PR template |
| 3 | **GitHub settings** | Description, topics, homepage, optional branch protection |
| 4 | **Gitleaks** | Pre-commit hook + `.pre-commit-config.yaml`, `.gitignore` hardening |
| 4.5 | **Code quality** | Auto-detect linters/formatters, generate Makefile + CI (26 plugins) |
| 5 | **Session hook** | Claude Code web session-start hook (auto-install deps) |
| 6 | **CI workflows** | `security.yml` (gitleaks scan), `release.yml` (tag-based releases) |
| 7 | **Quality gates** | `lessons-db scan` pre-commit hook, scope inference, top-5 lessons surfaced into CLAUDE.md |
| 8 | **AI code review** | Ollama-powered code review via local LLM |
| 9 | **Embeddings** | Semantic code search via nomic-embed-text |
| 10 | **Mode-based dirs** | `docs/plans/`, `tasks/`, `pipeline-status.md` scaffolded per project mode |
| 11 | **Draft artifacts** | PRD skeleton (all modes), MRD + risk log + roadmap (product/lib modes) |
| 12 | **Supporting files** | `AGENTS.md` + `gitleaks.toml` from kit templates |
| 13 | **Security gate** | Optional: security-reviewer agent scan before making repo public |
| 14 | **Verification** | Status table of all checks, next steps |

### Project Modes

`/setup-repo` asks which **project mode** applies — this shapes the lifecycle artifacts scaffolded:

| Mode | When | Extra artifacts |
|------|------|----------------|
| `internal` | Personal tools, automation, scripts | PRD, risk log, tech spec |
| `product` | User-facing product with external users | + MRD, personas, roadmap, release plan |
| `lib` | Open source library for others to consume | + Public-facing ROADMAP.md, contributor docs |

`claude-init --product` and `claude-init --lib` set the mode without the interactive pipeline.

## What Gets Installed

```text
~/.claude/
  kit/
    VERSION                 # Kit version (1.0.0)
    config.env              # Your configuration
    templates/              # CLAUDE.md templates (node, python, general) + PR template
                            # AGENTS.md, pipeline-status-internal.md, pipeline-status-product.md
    hookify-rules/          # Safety rules (5 rules)
    workflows/              # CI workflow templates (security, release)
    hooks/                  # Session hook templates + goal-reflection + improvement-loop
    plugins/                # Code quality plugins (26 plugins)
    linter-configs/         # Config templates for linters/formatters
    gitleaks.toml           # Allowlist for test fixture credentials
  skills/
    setup-repo/SKILL.md     # The /setup-repo skill (14-phase pipeline)
    create-tech-spec/       # /create-tech-spec — architecture decision contract
    create-risk-log/        # /create-risk-log — risks scored by likelihood × impact
    create-qa-plan/         # /create-qa-plan — acceptance criteria test matrix
    create-adr/             # /create-adr — architecture decision records
    create-retrospective/   # /create-retrospective — project close-out + lesson capture
    create-mrd/             # /create-mrd — market requirements (product/lib modes)
    create-roadmap/         # /create-roadmap — milestone planning
    create-release-plan/    # /create-release-plan — launch checklist + rollback plan

~/.local/bin/
  claude-init               # Project initializer (--product, --lib mode flags)
  lint-install              # Auto-detect & install code quality tools
  ollama-code-review        # AI code review (any language)
  generate-embeddings       # Semantic code embeddings
```

## Configuration

Edit `~/.claude/kit/config.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `GITHUB_ORG` | `your-username` | GitHub org/username for repo creation |
| `DEFAULT_VISIBILITY` | `private` | Default repo visibility |
| `OLLAMA_URL` | `http://localhost:11434` | Ollama API endpoint |
| `OLLAMA_REVIEW_MODEL` | `qwen2.5-coder:14b` | Model for code review |
| `OLLAMA_EMBED_MODEL` | `nomic-embed-text` | Model for embeddings |
| `TEMPLATE_NODE_REPO` | (empty) | Template repo for Node projects |
| `TEMPLATE_PYTHON_REPO` | (empty) | Template repo for Python projects |

## Requirements

**Required:**
- Git
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

**Recommended:**
- [GitHub CLI](https://cli.github.com/) (`gh`) — for repo creation and settings
- [pre-commit](https://pre-commit.com/) — for gitleaks hook

**Optional (features degrade gracefully without these):**
- [Ollama](https://ollama.com/) — for AI code review and semantic embeddings
- `jq` — for embedding generation
- `curl` — for ollama API calls

## Standalone Scripts

Each script works independently, outside of `/setup-repo`:

```bash
# Initialize a project with CLAUDE.md and safety rules
claude-init [node|python|general] [--product|--lib]

# Auto-detect & install code quality tools (linters, formatters, CI)
lint-install [--dry-run] [--only core|recommended|all] [--skip PLUGIN] [--project-root DIR]

# Run AI code review on a project
ollama-code-review [--lang python] [--model deepseek-coder:6.7b] ./my-project

# Generate semantic embeddings for code search
generate-embeddings [--model nomic-embed-text] [--src-dir src/]

# Check for anti-patterns in staged files (replaces lesson-check)
lessons-db scan --target . --baseline HEAD
```

## Code Quality Plugins

`lint-install` auto-detects project content and installs appropriate tools using a plugin system:

| Tier | Plugins | Auto-detects |
|------|---------|-------------|
| **Core** | shellcheck, eslint, ruff, prettier, editorconfig | Shell scripts, Node.js, Python, all projects |
| **Recommended** | typescript, mypy, npm-audit, pip-audit, commitlint, lint-staged, pre-commit, cspell | TypeScript, Python types, lock files, git repos |
| **Advanced** | actionlint, markdownlint, yamllint, hadolint, knip, vulture, size-limit, coverage, codeql, sonarcloud, codety, megalinter, release-please | GitHub Actions, Dockerfiles, CI integrations |

```bash
# List all available plugins
lint-install --list

# Preview what would be installed
lint-install --dry-run

# Install core + recommended (default)
lint-install

# Install everything including advanced CI integrations
lint-install --only all

# Skip specific plugins
lint-install --skip megalinter,sonarcloud
```

### Running Lint

After `lint-install`, use `make lint` to run all installed linters in one command:

```bash
make lint          # Run all linters
make lint-sh       # shellcheck — Bash script correctness
make lint-yaml     # yamllint — YAML syntax and style
make lint-md       # markdownlint — Markdown structure
make lint-spell    # cspell — Spelling across all files
make lint-actions  # actionlint — GitHub Actions workflow correctness
make test          # validate + lint (full quality gate)
```

### Graceful Failure

If a tool isn't installed, `lint-install` prints a `[warn]` or `[info]` hint and continues — it never aborts the run. Python CLI tools (`yamllint`) are installed via `pipx` when available, falling back to `pip`. CI-only tools (`codeql`, `megalinter`, `sonarcloud`) just copy workflow files with no local binary needed.

## Customization

### Templates

Edit files in `templates/` before installing, or edit directly in `~/.claude/kit/templates/` after. Templates use `{{PLACEHOLDER}}` syntax — `claude-init` replaces `{{PROJECT_NAME}}` automatically; others are filled in manually or by `/setup-repo`.

Every `CLAUDE.md` template ships with an `## AI Workflow` section encoding five core disciplines: spec-first development, narrow slices, multi-pass critique, run-locally verification, and context reset cadence. Edit this section to match your team's conventions.

`pull_request_template.md` is dropped into `.github/` of every new project with a checklist that includes AI-generated code review — reminding reviewers not to blind-trust model output.

### Hookify Rules

Five safety rules are included. To customize:
- Edit rules in `hookify-rules/` before installing
- Or edit in `~/.claude/kit/hookify-rules/` after
- Set `enabled: false` in frontmatter to disable a rule
- Add new `.local.md` files following the same format

### Workflows

CI workflow templates in `workflows/` are copied to new projects. Modify them to match your CI needs (different runners, additional checks, etc.).

## Uninstall

```bash
bash uninstall.sh
```

Removes all installed files. Project files created by `/setup-repo` are not affected.

## License

MIT
