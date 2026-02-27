# AGENTS.md — {{PROJECT_NAME}}

Instructions for AI agents and Claude Code operating in this repository.

## Quick Start
```bash
{{INSTALL_COMMAND}}
{{TEST_COMMAND}}
```

## Architecture
{{ONE_LINE_DESCRIPTION}}

Key directories:
- `src/` or `{{PACKAGE}}/` — source code
- `tests/` — test suite
- `docs/plans/` — implementation plans and tech specs
- `tasks/` — PRD, risk log, pipeline status

## Commands Agents Must Know
- Run tests: `{{TEST_COMMAND}}`
- Lint: `make lint`
- Format: `make format`
- Check lessons: `lessons-db scan --staged-only`

## What NOT to Do
- Never commit `.env` or secrets
- Never skip tests before committing
- Never claim done without running `/verify`
- Never start implementing without checking `/check-lessons` first

## Pipeline Status
See `tasks/pipeline-status.md` for current project phase.
