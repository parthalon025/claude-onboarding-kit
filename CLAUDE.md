# claude-onboarding-kit

Bootstrap script and templates for Claude Code project setup.

## Commands

```bash
./bin/claude-init [node|python|general]   # Run from target project directory
```

## Architecture

- `bin/claude-init` — main bootstrap script (auto-detects project type)
- `templates/` — CLAUDE.md starters: `CLAUDE.md.node`, `CLAUDE.md.python`, `CLAUDE.md.general`
- `hookify-rules/` — portable hookify rules copied into new projects

## How It Works

`claude-init` is a bash script run from inside any new project directory. It:
1. Inits git + creates private GitHub repo
2. Applies GitHub best practices (description, topics, homepage)
3. Creates standard dirs (`src/`, `tests/`, `docs/plans/`)
4. Copies the appropriate CLAUDE.md template
5. Installs hookify safety rules into `.claude/`

`KIT_DIR` is derived from the script's own location — edit templates/rules here, not in `~/.claude/kit/`.

## Conventions

- `~/.local/bin/claude-init` is a symlink to `bin/claude-init` — always edit here
- Hookify rules use `hookify.*.local.md` naming (git-ignored in target projects)
- Templates use `{{PLACEHOLDER}}` tokens replaced by `sed` at init time
