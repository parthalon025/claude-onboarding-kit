# Contributing to claude-onboarding-kit

Thank you for contributing. This document covers how to add plugins, skills, and templates — plus code style requirements and the PR process.

---

## Table of Contents

- [How to Add a Lint Plugin](#how-to-add-a-lint-plugin)
- [How to Submit a New Skill](#how-to-submit-a-new-skill)
- [How to Contribute a CLAUDE.md Template Improvement](#how-to-contribute-a-claudemd-template-improvement)
- [Code Style](#code-style)
- [PR Process](#pr-process)

---

## How to Add a Lint Plugin

Plugins live in `plugins/`. Each plugin is a self-contained `.sh` file that declares its tier, provides a `detect()` function, an `install()` function, a `configure()` function, and a `generate_output()` function. The shared library (`plugins/lib.sh`) provides all detection helpers and state management — source it rather than duplicating logic.

### File structure

```bash
#!/usr/bin/env bash
# Plugin: <tool-name> — one-line description
TIER="$TIER_CORE"          # one of: $TIER_CORE | $TIER_RECOMMENDED | $TIER_ADVANCED
PLUGIN_NAME="<tool-name>"
PLUGIN_DESC="<short description>"

detect() {
    # Return 0 (true) when this plugin should be installed.
    # Use helpers from lib.sh: is_node, is_python, has_file, has_dir, has_files, etc.
    is_node && has_file "package.json"
}

install() {
    # Install the tool. Check if already present first.
    if cmd_exists <tool>; then
        echo "<tool> already installed"
        return
    fi
    npm install --save-dev <tool>
}

configure() {
    # Add Makefile targets and CI steps via lib.sh helpers.
    add_make_target "lint-<tool>" "<tool> ."
    add_make_lint_dep "lint-<tool>"
}

generate_output() {
    # Write any config files the tool needs.
    # Use write_config from lib.sh to avoid overwriting existing configs.
    write_config ".toolrc" "$(cat <<'EOF'
# <tool> config
EOF
)"
}
```

### Tier guidelines

| Tier | When to use |
|------|-------------|
| `$TIER_CORE` | Every project of this type needs it (e.g., eslint for Node, ruff for Python) |
| `$TIER_RECOMMENDED` | Adds clear value, low friction to install |
| `$TIER_ADVANCED` | Specialized, high-overhead, or requires external service |

### Detection logic

`detect()` must return quickly and produce zero output. Use the helpers in `lib.sh`:

- `is_node` — `package.json` present
- `is_python` — `pyproject.toml`, `setup.py`, or `setup.cfg` present
- `has_file <path>` — single file check relative to `$PROJECT_ROOT`
- `has_dir <path>` — directory check
- `has_files <glob>` — glob search excluding `node_modules/`, `.venv/`, `vendor/`, `.git/`

### Testing your plugin

Run `lint-install --dry-run --project-root <test-dir>` against a project that should trigger your plugin. Verify it appears in the "would install" list. Then run without `--dry-run` and confirm the tool is installed and the Makefile target works.

Run `shellcheck plugins/<your-plugin>.sh` before submitting.

---

## How to Submit a New Skill

Skills live in `skills/<skill-name>/SKILL.md`. Each skill is a Claude markdown document with YAML frontmatter.

### Required frontmatter fields

```yaml
---
name: <skill-name>
description: <one sentence — shown in skill listings and help output>
---
```

Optional frontmatter:

```yaml
disable-model-invocation: true   # set when skill only runs shell commands, no LLM generation
```

### Skill content guidelines

- Start with a one-paragraph summary of what the skill does and when to use it.
- Use `## Phase N: <name>` headers to structure multi-step skills.
- All shell commands must be in fenced `bash` code blocks.
- Parameterize via `$ARGUMENTS` for user-supplied inputs.
- All commands must be idempotent — safe to re-run on an existing project.
- Reference kit resources via `$KIT_DIR` (set to `~/.claude/kit/` by `install.sh`).

### Naming convention

- Directory: `skills/<verb>-<noun>/` (e.g., `skills/create-prd/`, `skills/setup-repo/`)
- File: always `SKILL.md` inside that directory

### Testing your skill

1. Install the kit: `bash install.sh`
2. In a test project, invoke the skill via Claude Code: `/<skill-name>`
3. Verify all generated files, commands, and outputs match intent

---

## How to Contribute a CLAUDE.md Template Improvement

Templates live in `templates/`. The three primary templates are:

- `CLAUDE.md.node` — Node.js projects
- `CLAUDE.md.python` — Python projects
- `CLAUDE.md.general` — Language-agnostic projects

### Placeholder convention

Templates use `{{PLACEHOLDER}}` tokens replaced by `sed` at init time. Current tokens:

| Token | Replaced with |
|-------|---------------|
| `{{PROJECT_NAME}}` | Repository name |
| `{{GITHUB_ORG}}` | GitHub org or username |
| `{{YEAR}}` | Current year |

Do not add hardcoded values where a placeholder would work. Do not invent new placeholder tokens without updating `bin/claude-init` to replace them.

### What belongs in templates

- Project-type-specific commands (build, test, lint)
- Conventions sections (naming, file layout, import style)
- Claude Code behavioral rules specific to the stack
- References to kit-installed scripts

### What does not belong in templates

- Project-specific business logic or domain rules
- Credentials, tokens, or API keys (even as examples)
- Absolute paths (use `$HOME`, `%h/`, or `Path.home()`)

---

## Code Style

All `.sh` files in this repository must pass `shellcheck` with no errors or warnings.

```bash
shellcheck script.sh
```

For bulk checks across the repo:

```bash
find . -name "*.sh" -not -path "./.git/*" | xargs shellcheck
```

Additional conventions:

- Use `#!/usr/bin/env bash` shebangs (not `/bin/bash`)
- Quote all variable expansions: `"$VAR"`, not `$VAR`
- Use `[[ ]]` for conditionals, not `[ ]`
- Declare local variables with `local` inside functions
- Functions use `snake_case`
- Constants use `UPPER_SNAKE_CASE`
- Prefer `printf` over `echo` for formatted output

---

## PR Process

1. **Fork** the repository and create a branch from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes.** Keep commits focused — one logical change per commit.

3. **Run shellcheck** on all modified `.sh` files:
   ```bash
   find . -name "*.sh" -not -path "./.git/*" | xargs shellcheck
   ```

4. **Test the install path** end-to-end:
   ```bash
   TMPDIR=$(mktemp -d)
   KIT_DEST="$TMPDIR/.claude/kit" bash install.sh
   ```

5. **Describe your changes** in the PR body:
   - What problem does this solve?
   - What does the change do?
   - How was it tested?

6. **All checks must pass** before merge — shellcheck, install smoke test, and any tests in `tests/`.

7. **One approval required** before merge to main.

For bug reports or feature requests, open a GitHub Issue before starting a large PR. This avoids duplicate work and ensures the direction aligns with the project roadmap.
