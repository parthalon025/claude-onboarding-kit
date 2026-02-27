# claude-onboarding-kit

Bootstrap script and templates for Claude Code project setup. Run one command in any new project directory to get git, GitHub, CLAUDE.md, hookify safety rules, and standard directory structure — all wired up.

## Usage

```bash
cd my-new-project
claude-init           # auto-detects node/python/general
claude-init python    # explicit type
```

## What It Sets Up

| Component | Details |
|-----------|---------|
| Git + GitHub | `git init`, private repo, push |
| GitHub metadata | Description prompt, auto-topics, homepage |
| Directory structure | `src/`, `tests/`, `docs/plans/` |
| Community files | `LICENSE` (MIT), `SECURITY.md`, issue templates |
| Claude Code | `CLAUDE.md` from template, `.claude/` hookify rules |
| `.gitignore` | Language-appropriate entries + Claude local files |

## Installation

```bash
git clone git@github.com:parthalon025/claude-onboarding-kit.git ~/Documents/projects/claude-onboarding-kit
ln -sf ~/Documents/projects/claude-onboarding-kit/bin/claude-init ~/.local/bin/claude-init
chmod +x ~/Documents/projects/claude-onboarding-kit/bin/claude-init
```

## Customization

- **Templates:** Edit `templates/CLAUDE.md.{node,python,general}` — `{{PLACEHOLDER}}` tokens are replaced at init time
- **Hookify rules:** Add/edit files in `hookify-rules/` — copied into `.claude/` of each new project
- **Script:** `bin/claude-init` — `KIT_DIR` is derived from the script's own location, so the repo is self-contained

## Structure

```
claude-onboarding-kit/
├── bin/
│   └── claude-init          # bootstrap script
├── templates/
│   ├── CLAUDE.md.node
│   ├── CLAUDE.md.python
│   └── CLAUDE.md.general
└── hookify-rules/
    └── hookify.*.local.md   # safety rules
```
