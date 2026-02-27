# Claude Onboarding Kit — Consolidation & Pipeline Design

**Date:** 2026-02-27
**Status:** Approved
**Scope:** Script consolidation (Option A) + mode-based product lifecycle pipeline

---

## Problem Statement

The kit currently wires **tools** into new projects (lint, security, Ollama, lessons-db) but not
Claude's **operating system** — the workflows, rules, and hooks that make Claude effective. It also
has script duplication across `autonomous-coding-toolkit` and `Documents/scripts/` that diverged
over time. `lesson-check.sh` is deprecated in favor of `lessons-db`.

Additionally, the setup pipeline is missing the definition phase of a project lifecycle — PRD,
technical spec, user research, risk log — which means projects start coding before the "what and
why" is documented.

---

## Goals

1. Make `claude-onboarding-kit` the canonical source for shared scripts (Option A consolidation)
2. Replace `lesson-check` everywhere with `lessons-db` CLI
3. Add mode-based project lifecycle pipeline (Internal Tool / Product / Open Source Library)
4. Propagate Claude's full operating discipline into every new project via CLAUDE.md templates
5. Ship new skills for lifecycle artifacts not yet covered
6. Prepare the repo for eventual public release (security gate required first)

---

## Non-Goals

- Merging `autonomous-coding-toolkit` into this repo (Option B — rejected)
- Counter/reflect/check skills (excluded by design)
- Making the repo public in this iteration (security review is a gate, not part of this work)

---

## Architecture

### Script Ownership (Option A)

| Script | Canonical Home | Other Locations |
|--------|---------------|-----------------|
| `lesson-check.sh` | **Archived** — `_archived/` in kit + ACT | Remove from install lists |
| `ollama-code-review.sh` | `claude-onboarding-kit/scripts/` | `Documents/scripts/` → thin wrapper |
| `lint-install.sh` | `claude-onboarding-kit/scripts/` | No other copies |
| `generate-embeddings.sh` | `claude-onboarding-kit/scripts/` | No other copies |

`lessons-db` CLI is the canonical anti-pattern scanner. All `lesson-check` references removed.

---

## Mode-Based Workflow Pipeline

`/setup-repo` Phase 1 asks: **Internal tool, product, or open source library?**

### Internal Tool Pipeline
```
Brainstorm → PRD → Risk Log → Tech Spec → Worktree
→ Execute (TDD) → QA Plan → Verify → Finish → Retrospective
```

### Product Pipeline
```
Brainstorm → MRD → Personas → PRD → Roadmap → Risk Log → Tech Spec
→ Design/UX → Worktree → Execute (TDD) → QA Plan → Release Plan → Verify → Finish → Retrospective
```

### Open Source Library Pipeline
```
Brainstorm → Tech Spec → ADRs → PRD → Roadmap (ROADMAP.md) → Risk Log
→ Worktree → Execute (TDD) → QA Plan → CONTRIBUTING.md → Release Plan
→ Verify → Finish → Retrospective
```

---

## Directory Structure by Mode

### Internal Tool
```
docs/plans/         # technical spec + implementation plans
docs/product/       # PRD
docs/decisions/     # ADRs (optional but available)
tasks/              # prd.json, risk-log.md, pipeline-status.md, progress.txt
```

### Product (adds)
```
docs/research/      # personas, user research
docs/design/        # UX notes, wireframe descriptions
docs/product/       # PRD, MRD, roadmap, release-plan, qa-plan
tasks/              # + stakeholders.md
```

### Open Source Library (adds)
```
ROADMAP.md          # repo root — public contributor-facing
CONTRIBUTING.md     # repo root
docs/product/       # PRD, qa-plan, release-plan
docs/decisions/     # ADRs — expected for OSS
```

---

## New Skills (ship with kit → install to ~/.claude/skills/)

| Skill | Output | Modes |
|-------|--------|-------|
| `/create-tech-spec` | `docs/plans/tech-spec.md` | All |
| `/create-risk-log` | `tasks/risk-log.md` | All |
| `/create-qa-plan` | `docs/product/qa-plan.md` | All |
| `/create-adr` | `docs/decisions/NNNN-title.md` | All |
| `/create-retrospective` | `docs/retrospective.md` | All |
| `/create-mrd` | `docs/product/mrd.md` | Product, OSS |
| `/create-roadmap` | `docs/product/roadmap.md` (Product) or `ROADMAP.md` (OSS) | Product, OSS |
| `/create-release-plan` | `docs/product/release-plan.md` | Product, OSS |

### Existing Skills Referenced (no new work)
- `/create-prd` — already exists
- `user-persona` — personas skill already in catalog
- `brainstorming` — mandatory before features
- `frontend-design`, `responsive-layout`, `mobile-design` — UX phase
- `feature-dev`, `verify` — execution + completion

---

## CLAUDE.md Template Changes (all 3 templates: node, python, general)

### Additions to all templates

**`## Workflow Pipeline`** — mode-appropriate pipeline with slash commands listed inline.

**`## Project Artifacts`** — table of artifact files, what generates them, where they live.

**`## Lessons-Derived Rules`** — top 5 rules inline (not a doc pointer):
1. No bare exception swallowing — log before returning fallback
2. Async discipline — no `async def` without I/O; verify `await` at call sites
3. Subscriber lifecycle — store callback ref on `self`, unsubscribe in `shutdown()`
4. Schema changes update all consumers — same PR for producer + consumer
5. `create_task` done_callback — every unwaited task needs error visibility

**`## Code Factory Workflow`** — full pipeline: brainstorm → research → PRD → plan → worktree → execute → verify → finish. Reference `/create-prd` and `progress.txt` append-only convention.

**`## Lean Gate`** — hypothesis first · MVP scope · named users · success metric · pivot trigger. Flagging instruction for Claude included.

**`## Scope Tags`** — empty section with comment `# e.g., python, async, sqlite`. Required for lessons-db scope inference.

**`## Skills`** — key invocable skills with when-to-use guidance:
- `check-lessons` — before planning
- `capture-lesson` — after bugs
- `brainstorming` — mandatory before new features
- `create-prd`, `create-risk-log`, `create-tech-spec`
- `feature-dev`, `verify`
- Mode-specific skills appended per mode

---

## `/setup-repo` Phase Updates

| Phase | Change |
|-------|--------|
| Phase 1 | Add mode question (Internal Tool / Product / Open Source Library) |
| Phase 7 | Replace `lesson-check` pre-commit with `lessons-db scan --staged-only`; run `lessons-db search` on project type (top 5 results surfaced into CLAUDE.md `## Lessons` section); run `scope-infer.sh` |
| Phase 8 | Create mode-appropriate directory structure |
| New Phase 9 | Claude generates draft artifact content from Phase 1 description (not empty stubs) — skeleton MRD, personas, risk log drafted from project description |
| New Phase 10 | Copy `AGENTS.md` template; copy `gitleaks.toml` allowlist starter |
| New Phase 11 | Security-reviewer agent scan — gate before `gh repo edit --visibility public` (opt-in, not run on every setup) |

---

## `.claude/settings.json` Template

Add hooks beyond session-start:

```json
{
  "hooks": {
    "SessionStart": [
      { "type": "command", "command": ".claude/hooks/session-start.sh" },
      { "type": "command", "command": ".claude/hooks/goal-reflection.sh" }
    ],
    "Stop": [
      { "type": "command", "command": ".claude/hooks/improvement-loop.sh" }
    ]
  }
}
```

Hook templates added to kit's `hooks/` directory:
- `goal-reflection.sh` — injects goal-reflection prompt at session start
- `improvement-loop.sh` — captures improvement prompts at session end

---

## Pipeline Status Tracking

`tasks/pipeline-status.md` created at setup time, updated by each skill as it completes a phase:

```markdown
# Pipeline Status

| Phase | Artifact | Status | Date |
|-------|----------|--------|------|
| Brainstorm | docs/plans/design.md | ✅ | 2026-02-27 |
| PRD | tasks/prd.json | ⬜ | — |
| Risk Log | tasks/risk-log.md | ⬜ | — |
| Tech Spec | docs/plans/tech-spec.md | ⬜ | — |
...
```

Prevents phase-skipping. Gives Claude a project state dashboard at session start.

---

## Kit Version Tracking

- `~/.claude/kit/VERSION` file written by `install.sh`
- Version stamp added to each project's CLAUDE.md header at setup: `# Kit version: X.Y.Z`
- Enables future `kit-upgrade` command to detect stale projects

---

## `claude-init` Mode Default

`claude-init` (quick scaffold, no interactive pipeline) defaults to **Internal Tool** mode.
Opt-in flag: `claude-init --product` or `claude-init --lib` for other modes.
All mode-appropriate CLAUDE.md template sections + directory structure created accordingly.

---

## Public Repo Files (kit itself)

Required before making kit public (separate from security gate):

| File | Purpose |
|------|---------|
| `CONTRIBUTING.md` | How to add lint plugins, submit PRD skills, contribute |
| `SECURITY.md` | Vulnerability reporting process |
| `CHANGELOG.md` | Version history |
| `examples/node/` | Minimal node project post-`/setup-repo` |
| `examples/python/` | Minimal python project post-`/setup-repo` |
| `gitleaks.toml` | Starter allowlist for test credentials |

---

## Quality Gate Wiring

Both modes add to CLAUDE.md:

```markdown
## Quality Gates
- Before committing: `lessons-db scan --staged-only`
- Before PRs: `quality-gate.sh --project-root .`
- Before claiming done: `/verify`
```

---

## Security Review Gate (Pre-Publish)

Phase 11 of `/setup-repo` — opt-in, triggered by `--publish` flag or explicit user request:

1. Run `security-reviewer` agent across entire kit repo
2. Scan for: hardcoded values, private hostnames, personal identifiers, API key patterns
3. Must pass before running `gh repo edit --visibility public`
4. Output saved to `docs/security-review-YYYY-MM-DD.md`

---

## `autonomous-coding-toolkit` Changes

| File | Change |
|------|--------|
| `scripts/lesson-check.sh` | Archive to `_archived/lesson-check.sh` with deprecation header |
| Any script calling `lesson-check` | Audit + update to call `lessons-db` CLI directly |
| Cross-reference to kit scripts | Update to use `~/.local/bin/` installed binaries |

---

## `Documents/scripts/` Changes

| File | Change |
|------|--------|
| `ollama-code-review.sh` | Replace with thin wrapper: `exec "$HOME/.local/bin/ollama-code-review" "$@"` |

---

## Open Questions (resolved)

- **lesson-check vs lessons-db:** `lessons-db` is canonical. `lesson-check` archived everywhere.
- **Repo visibility now:** Stay private. Security review is a gate before publishing.
- **Counter/reflect skills:** Excluded by design.
- **Roadmap doc:** Product + Open Source modes only. Internal Tool skips it.
- **Option A vs B vs C:** Option A — script consolidation only. ACT stays separate.
