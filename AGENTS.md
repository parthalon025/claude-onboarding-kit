# AGENTS.md — claude-onboarding-kit

Instructions for AI agents and Claude Code operating in this repository.

## Quick Start
```bash
bash install.sh
make test
```

## Architecture
Bootstrap kit — install once, run /setup-repo in any project.

Key directories:
- `bin/`, `scripts/`, `skills/`, `templates/` — kit source
- `tests/` — test suite
- `docs/plans/` — implementation plans and tech specs
- `tasks/` — PRD, risk log, pipeline status

## Commands Agents Must Know
- Run tests: `make test`
- Lint: `make lint`
- Format: `make format`
- Check lessons: `lessons-db scan --target . --baseline HEAD`

## What NOT to Do
- Never commit `.env` or secrets
- Never skip tests before committing
- Never claim done without running `/verify`
- Never start implementing without checking `/check-lessons` first

## Pipeline Status
See `tasks/pipeline-status.md` for current project phase.
