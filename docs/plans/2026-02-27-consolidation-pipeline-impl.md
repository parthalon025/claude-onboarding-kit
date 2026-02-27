# Consolidation & Mode-Based Pipeline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Consolidate scripts (Option A), replace lesson-check with lessons-db, add mode-based project lifecycle pipeline (Internal Tool / Product / Open Source Library), and propagate Claude's full operating discipline into every new project.

**Architecture:** Three parallel tracks — (A) consolidation/cleanup, (B) /setup-repo skill overhaul, (C) new skills + templates. Track A unblocks Track B. Track C is independent and parallelizable. install.sh is updated last to wire everything together.

**Tech Stack:** bash, markdown (skills/templates), YAML (workflows), JSON (settings), shellcheck for validation

**Design doc:** `docs/plans/2026-02-27-consolidation-and-pipeline-design.md`

---

## Validation Harness (do this first)

### Task 0: Create test/validation infrastructure

**Files:**
- Create: `tests/validate.sh`
- Create: `tests/validate-install.sh`

**Step 1: Write validate.sh**

```bash
#!/usr/bin/env bash
# Validates kit structure — run before and after changes
set -euo pipefail
PASS=0; FAIL=0
check() { local desc="$1" result="$2"
  if [[ "$result" == "ok" ]]; then echo "[ok] $desc"; ((PASS++))
  else echo "[!!] $desc"; ((FAIL++)); fi }

# Core files
check "install.sh exists" "$([ -f install.sh ] && echo ok || echo fail)"
check "uninstall.sh exists" "$([ -f uninstall.sh ] && echo ok || echo fail)"
check "bin/claude-init exists" "$([ -f bin/claude-init ] && echo ok || echo fail)"
check "skills/setup-repo/SKILL.md exists" "$([ -f skills/setup-repo/SKILL.md ] && echo ok || echo fail)"

# Templates
for t in node python general; do
  check "templates/CLAUDE.md.$t exists" "$([ -f "templates/CLAUDE.md.$t" ] && echo ok || echo fail)"
done

# lesson-check archived (not in scripts/)
check "lesson-check NOT in scripts/" "$([ ! -f scripts/lesson-check.sh ] && echo ok || echo fail)"

# New skills present
for s in create-tech-spec create-risk-log create-qa-plan create-adr \
          create-retrospective create-mrd create-roadmap create-release-plan; do
  check "skills/$s/SKILL.md exists" "$([ -f "skills/$s/SKILL.md" ] && echo ok || echo fail)"
done

# New hooks
for h in goal-reflection improvement-loop; do
  check "hooks/$h.sh exists" "$([ -f "hooks/$h.sh" ] && echo ok || echo fail)"
done

# Template sections present
for t in node python general; do
  f="templates/CLAUDE.md.$t"
  check "$t: has Lessons-Derived Rules" "$(grep -q 'Lessons-Derived Rules' "$f" && echo ok || echo fail)"
  check "$t: has Code Factory Workflow" "$(grep -q 'Code Factory Workflow' "$f" && echo ok || echo fail)"
  check "$t: has Lean Gate" "$(grep -q 'Lean Gate' "$f" && echo ok || echo fail)"
  check "$t: has Scope Tags" "$(grep -q 'Scope Tags' "$f" && echo ok || echo fail)"
  check "$t: has Skills section" "$(grep -q '## Skills' "$f" && echo ok || echo fail)"
  check "$t: has Workflow Pipeline" "$(grep -q 'Workflow Pipeline' "$f" && echo ok || echo fail)"
  check "$t: no lesson-check reference" "$(grep -qv 'lesson-check' "$f" && echo ok || echo fail)"
done

# setup-repo skill
f="skills/setup-repo/SKILL.md"
check "setup-repo: has mode question" "$(grep -q 'Internal tool\|product\|open source' "$f" && echo ok || echo fail)"
check "setup-repo: uses lessons-db not lesson-check" \
  "$(grep -q 'lessons-db' "$f" && ! grep -q 'lesson-check' "$f" && echo ok || echo fail)"
check "setup-repo: has Phase 9 (draft artifacts)" "$(grep -q 'Phase 9' "$f" && echo ok || echo fail)"
check "setup-repo: has Phase 11 (security gate)" "$(grep -q 'Phase 11' "$f" && echo ok || echo fail)"

# Public files
for f in CONTRIBUTING.md SECURITY.md CHANGELOG.md; do
  check "$f exists" "$([ -f "$f" ] && echo ok || echo fail)"
done

# gitleaks allowlist
check "gitleaks.toml exists" "$([ -f gitleaks.toml ] && echo ok || echo fail)"

# AGENTS.md template
check "templates/AGENTS.md exists" "$([ -f templates/AGENTS.md ] && echo ok || echo fail)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
```

**Step 2: Make executable and run to see baseline failures**
```bash
chmod +x tests/validate.sh
bash tests/validate.sh
```
Expected: many `[!!]` lines — confirms what we need to build.

**Step 3: Commit the harness**
```bash
git add tests/validate.sh
git commit -m "test: add validation harness for kit structure"
```

---

## Track A: Consolidation

### Task 1: Archive lesson-check.sh in kit

**Files:**
- Create: `_archived/lesson-check.sh` (move from `scripts/`)
- Delete: `scripts/lesson-check.sh`

**Step 1: Create _archived/ directory and move file**
```bash
mkdir -p _archived
# Add deprecation header then copy content
cat > _archived/lesson-check.sh << 'EOF'
#!/usr/bin/env bash
# DEPRECATED — archived 2026-02-27
# lessons-db is the canonical anti-pattern scanner.
# Install: pip install lessons-db
# Usage: lessons-db scan --staged-only
# This file is kept for reference only. Do not use.
EOF
cat scripts/lesson-check.sh >> _archived/lesson-check.sh
rm scripts/lesson-check.sh
```

**Step 2: Verify**
```bash
[ ! -f scripts/lesson-check.sh ] && echo "ok: removed" || echo "FAIL: still present"
[ -f _archived/lesson-check.sh ] && echo "ok: archived" || echo "FAIL: not found"
head -5 _archived/lesson-check.sh  # should show deprecation header
```

**Step 3: Commit**
```bash
git add _archived/lesson-check.sh scripts/lesson-check.sh
git commit -m "archive: deprecate lesson-check.sh — lessons-db is canonical"
```

---

### Task 2: Update install.sh (remove lesson-check from install list)

**Files:**
- Modify: `install.sh`

**Step 1: Find the lesson-check install line**
```bash
grep -n 'lesson-check' install.sh
```

**Step 2: Edit install.sh**

Find the scripts install loop and the echo line that lists installed scripts. Remove `lesson-check` from both. The echo line near line 73 currently reads:
```bash
echo "[+] Scripts → $BIN_DEST/{ollama-code-review,generate-embeddings,lesson-check,lint-install}"
```
Update to:
```bash
echo "[+] Scripts → $BIN_DEST/{ollama-code-review,generate-embeddings,lint-install}"
```

The loop at line 67-72 already uses `*.sh` glob — no change needed there since lesson-check.sh is gone from `scripts/`. But add a safety skip:
```bash
for script in "$KIT_SOURCE/scripts/"*.sh; do
    name="$(basename "$script" .sh)"
    [[ "$name" == "claude-init" ]] && continue
    [[ "$name" == "lesson-check" ]] && continue  # archived — use lessons-db instead
    cp "$script" "$BIN_DEST/$name"
    chmod +x "$BIN_DEST/$name"
done
```

**Step 3: Verify install.sh has no remaining lesson-check references**
```bash
grep 'lesson-check' install.sh && echo "FAIL: references remain" || echo "ok: clean"
```

**Step 4: Commit**
```bash
git add install.sh
git commit -m "fix: remove lesson-check from install — use lessons-db"
```

---

### Task 3: Update Documents/scripts/ollama-code-review.sh → thin wrapper

**Files:**
- Modify: `/home/justin/Documents/scripts/ollama-code-review.sh`

**Step 1: Check current file**
```bash
wc -l ~/Documents/scripts/ollama-code-review.sh
head -5 ~/Documents/scripts/ollama-code-review.sh
```

**Step 2: Replace with wrapper**
```bash
cat > ~/Documents/scripts/ollama-code-review.sh << 'EOF'
#!/usr/bin/env bash
# Thin wrapper — canonical source is claude-onboarding-kit/scripts/ollama-code-review.sh
# Install the kit to get the full version: bash ~/Documents/projects/claude-onboarding-kit/install.sh
CANONICAL="$HOME/.local/bin/ollama-code-review"
if [[ -x "$CANONICAL" ]]; then
    exec "$CANONICAL" "$@"
else
    echo "ERROR: ollama-code-review not installed."
    echo "Run: bash ~/Documents/projects/claude-onboarding-kit/install.sh"
    exit 1
fi
EOF
chmod +x ~/Documents/scripts/ollama-code-review.sh
```

**Step 3: Verify wrapper works**
```bash
~/Documents/scripts/ollama-code-review.sh --help 2>&1 | head -3
# Should either show help (if kit installed) or the install error
```

**Step 4: Commit in Documents workspace**
```bash
cd ~/Documents && git add scripts/ollama-code-review.sh
git commit -m "fix: ollama-code-review → thin wrapper, kit is canonical"
cd ~/Documents/projects/claude-onboarding-kit
```

---

### Task 4: Audit ACT for lesson-check references

**Files:**
- Modify: various files in `/home/justin/Documents/projects/autonomous-coding-toolkit/`

**Step 1: Find all lesson-check references in ACT**
```bash
grep -r 'lesson-check\|lesson_check' \
  ~/Documents/projects/autonomous-coding-toolkit/ \
  --include="*.sh" --include="*.md" --include="*.json" -l
```

**Step 2: For each .sh file found — update call to lessons-db**

Pattern to replace:
```bash
# Old
lesson-check --project-root . --staged-only
# Or
"$(command -v lesson-check)" --staged-only
```

Replace with:
```bash
lessons-db scan --staged-only
```

**Step 3: Archive ACT's lesson-check.sh**
```bash
mkdir -p ~/Documents/projects/autonomous-coding-toolkit/_archived
cp ~/Documents/projects/autonomous-coding-toolkit/scripts/lesson-check.sh \
   ~/Documents/projects/autonomous-coding-toolkit/_archived/lesson-check.sh
# Add deprecation header to archived copy
sed -i '1s|^|#!/usr/bin/env bash\n# DEPRECATED 2026-02-27 — use: lessons-db scan --staged-only\n# Original content below:\n|' \
   ~/Documents/projects/autonomous-coding-toolkit/_archived/lesson-check.sh
rm ~/Documents/projects/autonomous-coding-toolkit/scripts/lesson-check.sh
```

**Step 4: Verify**
```bash
grep -r 'lesson-check' ~/Documents/projects/autonomous-coding-toolkit/ \
  --include="*.sh" --include="*.md" | grep -v '_archived' \
  && echo "FAIL: references remain" || echo "ok: clean"
```

**Step 5: Commit in ACT**
```bash
cd ~/Documents/projects/autonomous-coding-toolkit
git add -A && git commit -m "archive: lesson-check.sh — lessons-db scan is canonical"
cd ~/Documents/projects/claude-onboarding-kit
```

---

## Track B: /setup-repo Skill Overhaul

### Task 5: Update Phase 1 — add mode question

**Files:**
- Modify: `skills/setup-repo/SKILL.md` (Phase 1 section, lines ~43-69)

**Step 1: Read current Phase 1**
```bash
grep -n "Phase 1" skills/setup-repo/SKILL.md
sed -n '40,70p' skills/setup-repo/SKILL.md
```

**Step 2: Add mode input to Phase 1 required inputs list**

After input #4 (Visibility), add:

```markdown
5. **Project mode** — what kind of project is this?
   - `internal` — Internal tool, personal automation, scripts (default)
   - `product` — User-facing product with external users
   - `lib` — Open source library or framework meant for others to consume

   This determines which lifecycle artifacts are created, which directories are
   scaffolded, and which workflow pipeline is documented in CLAUDE.md.
```

Add `PROJECT_MODE` to the summary confirmation table.

**Step 3: Verify**
```bash
grep -q 'Project mode\|internal\|product\|lib' skills/setup-repo/SKILL.md \
  && echo "ok" || echo "FAIL"
```

**Step 4: Commit**
```bash
git add skills/setup-repo/SKILL.md
git commit -m "feat(setup-repo): add project mode question to Phase 1"
```

---

### Task 6: Update Phase 7 — lessons-db + scope + search

**Files:**
- Modify: `skills/setup-repo/SKILL.md` (Phase 7 section)

**Step 1: Find current Phase 7**
```bash
grep -n "Phase 7" skills/setup-repo/SKILL.md
```

**Step 2: Replace the pre-commit hook block**

Old hook:
```bash
lesson-check --project-root . --staged-only || exit 1
```

New hook:
```bash
#!/bin/bash
# Anti-pattern scanner — checks staged files against known bad patterns
LESSONS_DB="$(command -v lessons-db 2>/dev/null)"
if [ -x "$LESSONS_DB" ]; then
    $LESSONS_DB scan --staged-only || exit 1
fi
```

**Step 3: Add lessons-db search block after hook wiring**

After the pre-commit hook section, add:

```markdown
### Surface relevant lessons at setup time

Run a targeted search based on project type and surface top matches
into the CLAUDE.md `## Lessons` section:

```bash
# Detect language and run targeted search
if command -v lessons-db &>/dev/null; then
    case "$PROJECT_TYPE" in
        python) QUERY="python async error handling sqlite context manager" ;;
        node)   QUERY="typescript node async promise error handling" ;;
        *)      QUERY="error handling logging fallback silent failure" ;;
    esac
    echo "## Top Lessons for This Project" >> CLAUDE.md
    echo "" >> CLAUDE.md
    lessons-db search "$QUERY" --top 5 --format brief >> CLAUDE.md 2>/dev/null || true
fi
```

### Run scope inference

```bash
if command -v scope-infer &>/dev/null; then
    scope-infer --project-root . --update-claude-md
fi
```
```

**Step 4: Verify**
```bash
grep -q 'lessons-db scan' skills/setup-repo/SKILL.md && echo "ok: scan" || echo "FAIL: scan"
grep -q 'scope-infer' skills/setup-repo/SKILL.md && echo "ok: scope" || echo "FAIL: scope"
grep -q 'lesson-check' skills/setup-repo/SKILL.md && echo "FAIL: old ref" || echo "ok: cleaned"
```

**Step 5: Commit**
```bash
git add skills/setup-repo/SKILL.md
git commit -m "feat(setup-repo): Phase 7 — lessons-db scan + search + scope inference"
```

---

### Task 7: Add Phases 8–11 to /setup-repo skill

**Files:**
- Modify: `skills/setup-repo/SKILL.md` (append new phases before Phase 10 Verification)

**Step 1: Find where Phase 10 (Verification) currently starts**
```bash
grep -n "Phase 10" skills/setup-repo/SKILL.md
```

**Step 2: Insert new phases before current Phase 10 (renumber Phase 10 → Phase 12)**

Add Phase 8 (Mode-based directory scaffold):
```markdown
## Phase 8: Mode-Based Directory Structure

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

Create `tasks/pipeline-status.md`:
```markdown
# Pipeline Status — {{PROJECT_NAME}}
Kit version: {{KIT_VERSION}}

| Phase | Artifact | Status | Date |
|-------|----------|--------|------|
| Brainstorm | docs/plans/design.md | ⬜ | — |
| PRD | tasks/prd.json | ⬜ | — |
| Risk Log | tasks/risk-log.md | ⬜ | — |
| Tech Spec | docs/plans/tech-spec.md | ⬜ | — |
[product/OSS rows added if applicable]
```
```

Add Phase 9 (Claude-generated artifact drafts):
```markdown
## Phase 9: Draft Lifecycle Artifacts

Using the project description from Phase 1, generate draft content for
core artifacts — user edits rather than starting from scratch.

**All modes:** Draft skeleton PRD using `/create-prd` with the description.

**Product + OSS:** Also draft:
- MRD skeleton (`/create-mrd`) — market context, target users, KPIs
- Risk log (`/create-risk-log`) — 3-5 likely risks given project type
- Roadmap skeleton (`/create-roadmap`) — 3 milestone rows

**Do not ask the user to fill these in now** — scaffold and move on.
Remind them in Phase 12 next steps.
```

Add Phase 10 (AGENTS.md + gitleaks):
```markdown
## Phase 10: Supporting Files

Copy template files:

```bash
KIT_DIR="${CLAUDE_KIT_DIR:-$HOME/.claude/kit}"

# AGENTS.md — multi-agent workflow documentation
cp "$KIT_DIR/templates/AGENTS.md" AGENTS.md
sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" AGENTS.md

# gitleaks allowlist for test credentials
cp "$KIT_DIR/gitleaks.toml" gitleaks.toml
```

Verify `.gitignore` includes:
- `.env`, `.env.*`, `!.env.example`
- `.claude/*.local.md`
- `client_secret*.json`
- `.embeddings/`
```

Add Phase 11 (Security gate — opt-in):
```markdown
## Phase 11: Security Review (Pre-Publish Gate)

**Only run if user requests `--publish` or explicitly asks to go public.**

```bash
# Run security-reviewer agent across the repo
# This must pass before: gh repo edit --visibility public
```

Ask Claude Code to invoke the `security-reviewer` agent:
- Scans for hardcoded values, private hostnames, personal identifiers, API key patterns
- Output saved to `docs/security-review-$(date +%Y-%m-%d).md`
- Must show zero findings before flipping visibility
```

Renumber old Phase 10 → Phase 12.

**Step 3: Verify**
```bash
grep -n "Phase [0-9]" skills/setup-repo/SKILL.md
# Should show Phases 0-12 in order
```

**Step 4: Commit**
```bash
git add skills/setup-repo/SKILL.md
git commit -m "feat(setup-repo): add Phases 8-11 — dirs, artifact drafts, AGENTS.md, security gate"
```

---

## Track C: New Skills

### Task 8: Create /create-tech-spec skill

**Files:**
- Create: `skills/create-tech-spec/SKILL.md`

**Step 1: Write the skill**

```markdown
---
name: create-tech-spec
description: Generate a technical specification document — architecture decisions, API contracts, data models, infrastructure constraints, performance requirements. Separate from the implementation plan (writing-plans). Output: docs/plans/tech-spec.md
---

# Create Technical Specification

Produces `docs/plans/tech-spec.md` — the engineering contract that explains
*why* the system is designed the way it is, not *how* to implement it task-by-task.

## Arguments
$ARGUMENTS — optional: feature or component name

## Process

### Step 1: Gather context
Ask (one at a time if not obvious from codebase):
1. What system/component is this spec for?
2. What are the key external interfaces (APIs, queues, databases, user-facing surfaces)?
3. What are the non-functional requirements (latency, throughput, availability, scale)?
4. What alternatives were considered and why rejected?

### Step 2: Generate spec

Output to `docs/plans/tech-spec.md`:

```markdown
# Technical Specification — [Component]

**Status:** Draft | Approved | Superseded
**Date:** YYYY-MM-DD
**Author:** [project name]

## Problem Statement
[One paragraph: what problem this solves and why it matters]

## Scope
**In scope:** [bullet list]
**Out of scope:** [bullet list]

## Architecture

### Overview
[2-3 paragraph description + ASCII diagram if helpful]

### Components
| Component | Responsibility | Technology |
|-----------|---------------|------------|
| ... | ... | ... |

### Data Flow
[Step-by-step: input → processing → output]

### Data Models
[Key entities, fields, types, constraints]

## API Contracts
[Endpoints/interfaces with request/response shapes]

## Infrastructure
[Hosting, storage, networking, environment variables needed]

## Non-Functional Requirements
| Requirement | Target | Measurement |
|-------------|--------|-------------|
| Latency | < 200ms p99 | ... |
| ... | ... | ... |

## Security Considerations
[Auth, authz, data sensitivity, attack surface]

## Alternatives Considered
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| [chosen] | ... | ... | Selected |
| [rejected] | ... | ... | Rejected because ... |

## Open Questions
- [ ] [question with owner and deadline]
```

### Step 3: Save and confirm
Save to `docs/plans/tech-spec.md`. Ask: "Does this spec look right? Any sections to expand?"

### Step 4: Update pipeline-status.md
```bash
# Mark Tech Spec as complete in tasks/pipeline-status.md
sed -i 's/| Tech Spec |.*⬜.*/| Tech Spec | docs\/plans\/tech-spec.md | ✅ | '"$(date +%Y-%m-%d)"' |/' tasks/pipeline-status.md
```
```

**Step 2: Create directory and file**
```bash
mkdir -p skills/create-tech-spec
# Write the content above to skills/create-tech-spec/SKILL.md
```

**Step 3: Verify**
```bash
[ -f skills/create-tech-spec/SKILL.md ] && echo "ok" || echo "FAIL"
grep -q 'data-models\|API Contracts\|Non-Functional' skills/create-tech-spec/SKILL.md && echo "ok: sections" || echo "FAIL"
```

**Step 4: Commit**
```bash
git add skills/create-tech-spec/
git commit -m "feat: add /create-tech-spec skill"
```

---

### Task 9: Create /create-risk-log skill

**Files:**
- Create: `skills/create-risk-log/SKILL.md`

**Step 1: Write the skill**

```markdown
---
name: create-risk-log
description: Generate a risk and dependency log — risks scored by likelihood × impact, mitigations, owners, and external dependencies. Output: tasks/risk-log.md
---

# Create Risk Log

Produces `tasks/risk-log.md`. Run during the definition phase, before implementation.

## Process

### Step 1: Identify risks
Ask: "What could prevent this project from succeeding?" Probe:
- Technical risks (unknown APIs, performance unknowns, dependency stability)
- External dependencies (third-party services, data sources, team dependencies)
- Scope risks (requirements changing, underestimated complexity)
- Timeline risks (blocking tasks, external approvals needed)

### Step 2: Generate risk-log.md

```markdown
# Risk Log — [Project Name]
**Last updated:** YYYY-MM-DD

## Risks

| ID | Risk | Likelihood | Impact | Score | Mitigation | Owner | Status |
|----|------|-----------|--------|-------|------------|-------|--------|
| R1 | [description] | H/M/L | H/M/L | 9/6/4/3/1 | [action] | — | Open |

Score = Likelihood × Impact (H=3, M=2, L=1): 9=critical, 6=high, 4/3=medium, 1=low

## External Dependencies

| Dependency | Type | Owner | Risk if Unavailable | Mitigation |
|------------|------|-------|--------------------|-----------|
| [name] | API/Service/Data/Team | [owner] | [impact] | [fallback] |

## Resolved Risks
[Move closed risks here with resolution note]
```

### Step 3: Update pipeline-status.md
```bash
sed -i 's/| Risk Log |.*⬜.*/| Risk Log | tasks\/risk-log.md | ✅ | '"$(date +%Y-%m-%d)"' |/' tasks/pipeline-status.md
```
```

**Step 2: Create file, verify, commit**
```bash
mkdir -p skills/create-risk-log
# write skill content
[ -f skills/create-risk-log/SKILL.md ] && echo "ok" || echo "FAIL"
git add skills/create-risk-log/ && git commit -m "feat: add /create-risk-log skill"
```

---

### Task 10: Create /create-qa-plan skill

**Files:**
- Create: `skills/create-qa-plan/SKILL.md`

**Step 1: Write the skill**

```markdown
---
name: create-qa-plan
description: Generate a QA test plan — scope, acceptance criteria mapping, edge cases, and sign-off criteria before implementation begins. Different from TDD (practice) — this is the planning contract. Output: docs/product/qa-plan.md
---

# Create QA Test Plan

Produces `docs/product/qa-plan.md`. Run after PRD is approved, before implementation.

## Process

### Step 1: Map PRD to test scope
Pull acceptance criteria from `tasks/prd.json` or PRD document.
For each criterion, define: happy path, failure cases, edge cases, boundary values.

### Step 2: Generate qa-plan.md

```markdown
# QA Test Plan — [Feature/Project]
**Date:** YYYY-MM-DD
**PRD reference:** tasks/prd.json

## Scope
**In scope:** [features being tested]
**Out of scope:** [explicitly excluded]

## Test Environments
| Environment | Purpose | Data |
|-------------|---------|------|
| Local | Development | Fixtures |
| CI | Automated gate | Fixtures |

## Acceptance Criteria Test Matrix

| AC ID | Criterion | Test Case | Input | Expected Output | Pass Criteria |
|-------|-----------|-----------|-------|----------------|---------------|
| AC-1 | [criterion] | [test name] | [input] | [output] | [pass condition] |

## Edge Cases & Boundary Tests
- [case 1]: [how to test]
- [case 2]: [how to test]

## Sign-Off Criteria
- [ ] All AC test cases pass
- [ ] No P0/P1 bugs open
- [ ] Performance targets met (see tech-spec)
- [ ] Security review passed (if applicable)

## Test Commands
```bash
# Run full suite
pytest tests/ -v  # or npm test

# Run specific acceptance test
pytest tests/test_ac1.py -v
```
```

### Step 3: Update pipeline-status.md
```bash
sed -i 's/| QA Plan |.*⬜.*/| QA Plan | docs\/product\/qa-plan.md | ✅ | '"$(date +%Y-%m-%d)"' |/' tasks/pipeline-status.md
```
```

**Step 2: Create file, verify, commit**
```bash
mkdir -p skills/create-qa-plan
git add skills/create-qa-plan/ && git commit -m "feat: add /create-qa-plan skill"
```

---

### Task 11: Create /create-adr skill

**Files:**
- Create: `skills/create-adr/SKILL.md`

**Step 1: Write the skill**

```markdown
---
name: create-adr
description: Create an Architecture Decision Record — documents a significant technical decision with context, options considered, and rationale. Output: docs/decisions/NNNN-title.md
---

# Create Architecture Decision Record (ADR)

Produces `docs/decisions/NNNN-title.md`. Use for any non-obvious technical
decision so future sessions (and future you) understand *why*, not just *what*.

## Arguments
$ARGUMENTS — decision title or description

## Process

### Step 1: Determine next ADR number
```bash
ls docs/decisions/ 2>/dev/null | grep -E '^[0-9]{4}' | wc -l
# Next number = count + 1, zero-padded to 4 digits
```

### Step 2: Generate ADR

```markdown
# ADR-NNNN: [Decision Title]

**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-XXXX
**Date:** YYYY-MM-DD
**Deciders:** [project / Claude]

## Context

[1-2 paragraphs: what situation forced this decision? What constraints exist?
What would happen if we don't decide now?]

## Decision

[1 paragraph: what we decided to do, stated plainly]

## Options Considered

| Option | Pros | Cons |
|--------|------|------|
| **[Chosen]** | [pros] | [cons] |
| [Alternative 1] | [pros] | [cons] |
| [Alternative 2] | [pros] | [cons] |

## Rationale

[Why the chosen option wins given the context and constraints]

## Consequences

**Positive:** [what gets better]
**Negative:** [what gets harder or is now ruled out]
**Risks:** [what could go wrong with this decision]

## Review Trigger

Revisit this decision if: [specific conditions — e.g., "traffic exceeds 10k req/s"]
```

### Step 3: Save file
```bash
mkdir -p docs/decisions
# Save to docs/decisions/NNNN-title.md
```
```

**Step 2: Create file, verify, commit**
```bash
mkdir -p skills/create-adr
git add skills/create-adr/ && git commit -m "feat: add /create-adr skill"
```

---

### Task 12: Create /create-retrospective skill

**Files:**
- Create: `skills/create-retrospective/SKILL.md`

**Step 1: Write the skill**

```markdown
---
name: create-retrospective
description: Generate a project retrospective at close-out — what worked, what didn't, lessons to capture, decisions that aged well or poorly. Feeds back into lessons-db. Output: docs/retrospective.md
---

# Create Project Retrospective

Produces `docs/retrospective.md`. Run at project close-out before archiving.

## Process

### Step 1: Gather context
Review: `tasks/pipeline-status.md`, `tasks/progress.txt`, git log, any open issues.

### Step 2: Generate retrospective

```markdown
# Project Retrospective — [Project Name]
**Date:** YYYY-MM-DD
**Duration:** [start → end]
**Mode:** Internal Tool | Product | Open Source Library

## Summary
[2-3 sentences: what was built, what shipped, what didn't]

## What Worked Well
- [specific practice or decision that paid off]
- [tool or workflow that saved time]

## What Didn't Work
- [specific pain point or mistake]
- [decision that should have been made differently]

## Decisions That Aged Well
| Decision | ADR | Why It Held Up |
|----------|-----|---------------|
| [decision] | ADR-NNNN | [reason] |

## Decisions to Revisit
| Decision | ADR | Revisit Trigger |
|----------|-----|----------------|
| [decision] | ADR-NNNN | [condition] |

## Lessons to Capture
For each item below, run `/capture-lesson` to add to lessons-db:
- [bug pattern or anti-pattern worth encoding]

## Metrics
| Metric | Target | Actual |
|--------|--------|--------|
| [from qa-plan / prd KPIs] | [target] | [actual] |
```

### Step 3: Capture lessons
For each lesson identified, prompt: "Run /capture-lesson to encode this into lessons-db."
```

**Step 2: Create file, verify, commit**
```bash
mkdir -p skills/create-retrospective
git add skills/create-retrospective/ && git commit -m "feat: add /create-retrospective skill"
```

---

### Task 13: Create /create-mrd skill (Product + OSS)

**Files:**
- Create: `skills/create-mrd/SKILL.md`

**Step 1: Write the skill**

```markdown
---
name: create-mrd
description: Generate a Market Requirements Document — market context, competitive landscape, target users, and measurable KPIs. For Product and Open Source Library modes. Output: docs/product/mrd.md
---

# Create Market Requirements Document

Produces `docs/product/mrd.md`. Run before PRD — defines the "why the market
needs this" that the PRD's "what we're building" answers.

## Arguments
$ARGUMENTS — product name or description

## Process

### Step 1: Gather market context (ask one at a time)
1. Who is the primary target user? (role, context, current pain)
2. What do they use today instead of this? (direct + indirect competitors)
3. What is the single biggest pain point this eliminates?
4. How will you know it succeeded? (specific, measurable KPI)

### Step 2: Generate MRD

```markdown
# Market Requirements Document — [Product Name]
**Date:** YYYY-MM-DD
**Status:** Draft | Approved

## Problem Statement
[2 paragraphs: market pain, who feels it, why current solutions fail]

## Target Users

### Primary User
- **Role:** [job title / context]
- **Pain:** [specific frustration in their words]
- **Current workaround:** [what they do today]
- **Desired outcome:** [what success looks like for them]

### Secondary Users (if any)
[Same structure]

## Competitive Landscape

| Solution | Strengths | Weaknesses | Why Users Switch Away |
|----------|-----------|-----------|----------------------|
| [Direct competitor] | ... | ... | ... |
| [Indirect substitute] | ... | ... | ... |
| **This product** | ... | ... | — |

## Unique Value Proposition
[One sentence: for [user] who [pain], [product] is the [category] that [benefit],
unlike [alternative] which [weakness].]

## Success Metrics (KPIs)

| Metric | Baseline | Target (90 days) | Measurement Method |
|--------|----------|------------------|--------------------|
| [primary KPI] | [current] | [goal] | [how measured] |
| [secondary KPI] | ... | ... | ... |

## Market Assumptions
These must hold for this product to succeed:
- [assumption 1] — validated by: [evidence or "TBD"]
- [assumption 2] — validated by: [evidence or "TBD"]

## Pivot Triggers
Stop and reassess if:
- [specific measurable condition, e.g., "< 10 active users after 30 days"]
```

### Step 3: Update pipeline-status.md
```bash
sed -i 's/| MRD |.*⬜.*/| MRD | docs\/product\/mrd.md | ✅ | '"$(date +%Y-%m-%d)"' |/' tasks/pipeline-status.md
```
```

**Step 2: Create file, verify, commit**
```bash
mkdir -p skills/create-mrd docs/product
git add skills/create-mrd/ && git commit -m "feat: add /create-mrd skill (Product + OSS modes)"
```

---

### Task 14: Create /create-roadmap skill (Product + OSS)

**Files:**
- Create: `skills/create-roadmap/SKILL.md`

**Step 1: Write the skill**

```markdown
---
name: create-roadmap
description: Generate a project roadmap with milestones and release targets. Product mode → docs/product/roadmap.md. Open Source Library mode → ROADMAP.md (repo root, public-facing).
---

# Create Roadmap

Produces `docs/product/roadmap.md` (Product) or `ROADMAP.md` (OSS Library).

## Arguments
$ARGUMENTS — optional mode override (product | lib)

## Process

### Step 1: Anchor to PRD and MRD
Pull features from `tasks/prd.json` or PRD. Group into milestones (3-5 max).
Ask: "What must ship in v1.0 vs. what is v1.1+?"

### Step 2: Generate roadmap

**Product mode (`docs/product/roadmap.md`):**
```markdown
# Roadmap — [Product Name]
**Last updated:** YYYY-MM-DD

## Now (current milestone)
**Goal:** [one sentence]
**Target:** [date or sprint]

| Feature | Priority | Status | Notes |
|---------|----------|--------|-------|
| [feature] | P0 | 🔨 In Progress | |
| [feature] | P0 | ⬜ Not started | |

## Next
**Goal:** [one sentence]
**Target:** [date or sprint]
| Feature | Priority | Status | Notes |
...

## Later
[Features deferred beyond next milestone — keep short]

## Not Doing (this year)
[Explicit descoping — prevents scope creep]
```

**OSS Library mode (`ROADMAP.md` — repo root):**
Same structure but written for external contributors:
- Add "How to contribute to this milestone" section
- Link to open issues for each feature
- Include "Help wanted" labels

### Step 3: Save to correct location
```bash
if [[ "$MODE" == "lib" ]]; then
    OUTPUT="ROADMAP.md"
else
    OUTPUT="docs/product/roadmap.md"
fi
```

### Step 4: Update pipeline-status.md
```bash
sed -i 's/| Roadmap |.*⬜.*/| Roadmap | '"$OUTPUT"' | ✅ | '"$(date +%Y-%m-%d)"' |/' tasks/pipeline-status.md
```
```

**Step 2: Create file, verify, commit**
```bash
mkdir -p skills/create-roadmap
git add skills/create-roadmap/ && git commit -m "feat: add /create-roadmap skill (Product + OSS)"
```

---

### Task 15: Create /create-release-plan skill (Product + OSS)

**Files:**
- Create: `skills/create-release-plan/SKILL.md`

**Step 1: Write the skill**

```markdown
---
name: create-release-plan
description: Generate a release plan — launch checklist, messaging, and post-launch monitoring. Output: docs/product/release-plan.md
---

# Create Release Plan

Produces `docs/product/release-plan.md`. Run after QA plan is approved,
before marking a milestone as ready to ship.

## Process

### Step 1: Confirm scope
What version/milestone is this release plan for? Pull from `docs/product/roadmap.md`.

### Step 2: Generate release-plan.md

```markdown
# Release Plan — [Product/Version]
**Target date:** YYYY-MM-DD
**Release type:** Major | Minor | Patch | Internal

## Release Checklist

### Pre-Release
- [ ] All acceptance criteria in qa-plan.md passing
- [ ] No open P0/P1 bugs
- [ ] Tech spec updated if architecture changed
- [ ] CHANGELOG.md updated
- [ ] Version bumped in package.json / pyproject.toml
- [ ] Security review passed (if going public)

### Release
- [ ] Tag created: `git tag v[version]`
- [ ] Tag pushed: `git push origin v[version]`
- [ ] GitHub Release created with changelog notes
- [ ] Deployment verified in target environment

### Post-Release (first 24 hours)
- [ ] Monitor error rates (baseline: [current rate])
- [ ] Monitor [primary KPI from MRD]
- [ ] Check for user-reported issues
- [ ] Rollback plan ready: [specific steps]

## Messaging

### Internal announcement
[1-2 sentences for internal/personal record]

### Public announcement (if applicable)
[Tweet/post draft — lead with user benefit, not technical detail]

## Rollback Plan
**Trigger:** [specific condition — e.g., error rate > 5x baseline]
**Steps:**
1. [step 1]
2. [step 2]

## Success Criteria (72 hours post-launch)
Derived from MRD KPIs:
- [ ] [KPI 1]: [target]
- [ ] [KPI 2]: [target]
```

### Step 3: Update pipeline-status.md
```bash
sed -i 's/| Release Plan |.*⬜.*/| Release Plan | docs\/product\/release-plan.md | ✅ | '"$(date +%Y-%m-%d)"' |/' tasks/pipeline-status.md
```
```

**Step 2: Create file, verify, commit**
```bash
mkdir -p skills/create-release-plan
git add skills/create-release-plan/ && git commit -m "feat: add /create-release-plan skill"
```

---

## Track D: Templates & Infrastructure Files

### Task 16: Overhaul CLAUDE.md templates (all 3)

**Files:**
- Modify: `templates/CLAUDE.md.node`
- Modify: `templates/CLAUDE.md.python`
- Modify: `templates/CLAUDE.md.general`

**Step 1: Define the shared sections to append to all 3 templates**

Add after existing content in each template:

```markdown
## Workflow Pipeline

{{WORKFLOW_PIPELINE}}

## Project Artifacts

| Artifact | File | Generate With |
|----------|------|--------------|
| PRD | `tasks/prd.json` | `/create-prd` |
| Risk Log | `tasks/risk-log.md` | `/create-risk-log` |
| Tech Spec | `docs/plans/tech-spec.md` | `/create-tech-spec` |
| QA Plan | `docs/product/qa-plan.md` | `/create-qa-plan` |
| Pipeline Status | `tasks/pipeline-status.md` | auto-generated at setup |

## Lessons-Derived Rules

1. **No bare exception swallowing** — log before returning fallback. Every `except` block logs.
2. **Async discipline** — no `async def` without I/O; verify `await` at every call site.
3. **Subscriber lifecycle** — store callback ref on `self`, unsubscribe in `shutdown()`.
4. **Schema changes update all consumers** — producer + consumer change in same PR.
5. **`create_task` done_callback** — every unwaited task needs error visibility.

## Code Factory Workflow

brainstorm → research → PRD → plan → worktree → execute → verify → finish

- Every feature starts with `/brainstorm` — no exceptions
- PRD before implementation: `/create-prd`
- Progress tracked in `tasks/progress.txt` (append-only)
- Never claim done without running `/verify`

## Lean Gate

Before building anything, confirm:
- **Hypothesis:** what specific user behavior are we predicting?
- **MVP:** what is the minimum version that tests this hypothesis? (≤ 2 weeks solo)
- **First users:** name 3 real humans who will use this in 30 days
- **Success metric:** how will we know it worked?
- **Pivot trigger:** at what point do we stop and change direction?

## Scope Tags

{{SCOPE_TAGS}}

## Skills

**Use these before acting — invoke with the Skill tool:**

| Skill | When |
|-------|------|
| `check-lessons` | Before planning — surfaces relevant past mistakes |
| `capture-lesson` | After bugs — encodes pattern into lessons-db |
| `brainstorming` | Mandatory before any new feature |
| `create-prd` | After brainstorm — machine-verifiable acceptance criteria |
| `create-risk-log` | Definition phase — identify blockers before writing code |
| `create-tech-spec` | Before implementation — architecture contract |
| `create-adr` | On any non-obvious technical decision |
| `feature-dev` | Implementation with codebase understanding |
| `verify` | Before claiming done or creating PR |
```

**Step 2: Define mode-specific `{{WORKFLOW_PIPELINE}}` substitutions**

Internal tool:
```
Brainstorm → PRD → Risk Log → Tech Spec → Worktree → Execute (TDD) → QA → Verify → Finish → Retrospective
```

Product (add to project artifacts table):
```
| MRD | `docs/product/mrd.md` | `/create-mrd` |
| Personas | `docs/research/personas.md` | `user-persona` skill |
| Roadmap | `docs/product/roadmap.md` | `/create-roadmap` |
| Release Plan | `docs/product/release-plan.md` | `/create-release-plan` |
```

**Step 3: For now, bake in Internal Tool pipeline as default**
The `/setup-repo` skill will do mode-specific substitution at setup time using `sed`.

**Step 4: Update each template file — append shared sections**
```bash
for t in node python general; do
  # Append to templates/CLAUDE.md.$t
done
```

**Step 5: Verify all 3 templates have required sections**
```bash
bash tests/validate.sh 2>&1 | grep "has Lessons\|has Code Factory\|has Lean\|has Scope\|has Skills\|has Workflow"
# All should show [ok]
```

**Step 6: Commit**
```bash
git add templates/
git commit -m "feat: overhaul CLAUDE.md templates — lessons rules, Code Factory, lean gate, skills"
```

---

### Task 17: Add hook templates

**Files:**
- Create: `hooks/goal-reflection.sh`
- Create: `hooks/improvement-loop.sh`

**Step 1: Write goal-reflection.sh**
```bash
#!/usr/bin/env bash
# Goal-reflection hook — injects goal context at session start
# Only runs for Claude Code sessions (local or remote)
set -euo pipefail

PIPELINE_STATUS="${CLAUDE_PROJECT_DIR:-$(pwd)}/tasks/pipeline-status.md"

if [[ ! -f "$PIPELINE_STATUS" ]]; then
  exit 0
fi

# Surface current pipeline phase to Claude
echo ""
echo "=== PROJECT STATUS ==="
grep '⬜\|🔨' "$PIPELINE_STATUS" | head -5
echo "====================="
echo ""
```

**Step 2: Write improvement-loop.sh**
```bash
#!/usr/bin/env bash
# Improvement-loop hook — captures improvement prompts at session end
# Only runs for Claude Code sessions
set -euo pipefail

QUEUE_FILE="$HOME/.claude/.improvement-queue"
TIMESTAMP="$(date -Iseconds)"

# Rotate through improvement questions
QUESTIONS=(
  "What took the most tokens this session? Could a routing map or cached doc prevent it?"
  "Did this session touch an integration boundary (Cluster B)? Have you traced one value end-to-end?"
  "What would you do differently if starting this task over?"
  "What pattern did you repeat that could be automated?"
)

IDX=$(( $(wc -l < "$QUEUE_FILE" 2>/dev/null || echo 0) % ${#QUESTIONS[@]} ))
QUESTION="${QUESTIONS[$IDX]}"

echo "  - ($TIMESTAMP): IMPROVEMENT CAPTURE: $QUESTION" >> "$QUEUE_FILE"
```

**Step 3: Make executable**
```bash
chmod +x hooks/goal-reflection.sh hooks/improvement-loop.sh
```

**Step 4: Verify**
```bash
[ -x hooks/goal-reflection.sh ] && echo "ok: goal-reflection" || echo "FAIL"
[ -x hooks/improvement-loop.sh ] && echo "ok: improvement-loop" || echo "FAIL"
```

**Step 5: Commit**
```bash
git add hooks/goal-reflection.sh hooks/improvement-loop.sh
git commit -m "feat: add goal-reflection + improvement-loop hook templates"
```

---

### Task 18: Create supporting template files

**Files:**
- Create: `templates/AGENTS.md`
- Create: `templates/pipeline-status-internal.md`
- Create: `templates/pipeline-status-product.md`
- Create: `gitleaks.toml`

**Step 1: Write AGENTS.md template**
```markdown
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
```

**Step 2: Write pipeline-status templates**

`templates/pipeline-status-internal.md`:
```markdown
# Pipeline Status — {{PROJECT_NAME}}
Kit version: {{KIT_VERSION}}

| Phase | Artifact | Status | Date |
|-------|----------|--------|------|
| Brainstorm | docs/plans/design.md | ⬜ | — |
| PRD | tasks/prd.json | ⬜ | — |
| Risk Log | tasks/risk-log.md | ⬜ | — |
| Tech Spec | docs/plans/tech-spec.md | ⬜ | — |
| QA Plan | docs/product/qa-plan.md | ⬜ | — |
| Implementation | — | ⬜ | — |
| Verify | — | ⬜ | — |
| Retrospective | docs/retrospective.md | ⬜ | — |
```

`templates/pipeline-status-product.md` — same + MRD, Personas, Roadmap, Release Plan rows.

**Step 3: Write gitleaks.toml starter**
```toml
# gitleaks.toml — allowlist for test/example credentials
# Prevents false positives from fixture data in tests

title = "{{PROJECT_NAME}} gitleaks config"

[extend]
useDefault = true

[[rules.allowlists]]
description = "Test fixture credentials"
regexes = [
  "test[-_]token",
  "fake[-_](key|token|secret|api)",
  "example[-_](key|token)",
  "sk-fake",
  "REPLACE_ME",
  "your[-_](api[-_])?(key|token)",
]
paths = [
  "tests/",
  "examples/",
  ".env.example",
  "config.env.example",
]
```

**Step 4: Verify**
```bash
[ -f templates/AGENTS.md ] && echo "ok: AGENTS.md" || echo "FAIL"
[ -f gitleaks.toml ] && echo "ok: gitleaks.toml" || echo "FAIL"
grep -q 'allowlists\|test.*token' gitleaks.toml && echo "ok: allowlist" || echo "FAIL"
```

**Step 5: Commit**
```bash
git add templates/AGENTS.md templates/pipeline-status-*.md gitleaks.toml
git commit -m "feat: add AGENTS.md template, pipeline-status templates, gitleaks allowlist"
```

---

### Task 19: Update install.sh — wire new skills, hooks, VERSION

**Files:**
- Modify: `install.sh`
- Create: `VERSION`

**Step 1: Create VERSION file**
```bash
echo "1.0.0" > VERSION
```

**Step 2: Update install.sh to install all new skills**

After the existing skill install block, add:
```bash
# --- All skills ---
for skill_dir in "$KIT_SOURCE/skills/"*/; do
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$HOME/.claude/skills/$skill_name"
    cp "$skill_dir/SKILL.md" "$HOME/.claude/skills/$skill_name/"
    echo "[+] Skill → ~/.claude/skills/$skill_name/"
done
```

(Replace the hardcoded single-skill copy)

**Step 3: Add VERSION stamp to install**
```bash
# --- Version ---
KIT_VERSION="$(cat "$KIT_SOURCE/VERSION")"
cp "$KIT_SOURCE/VERSION" "$KIT_DEST/VERSION"
echo "[+] Kit version $KIT_VERSION installed"
```

**Step 4: Add new hooks to install**
```bash
# Hook templates now include goal-reflection and improvement-loop
# (already covered by the cp -r hooks/ block — no additional change needed)
# Verify:
echo "[+] Hook templates → $KIT_DEST/hooks/ ($(ls "$KIT_SOURCE/hooks/" | wc -l) templates)"
```

**Step 5: Verify install.sh runs cleanly on dry path**
```bash
bash -n install.sh && echo "ok: syntax" || echo "FAIL: syntax error"
grep -q 'VERSION' install.sh && echo "ok: version" || echo "FAIL"
grep -c 'skills/' install.sh  # should show skill install block
```

**Step 6: Commit**
```bash
git add install.sh VERSION
git commit -m "feat: update install.sh — all skills, VERSION stamp, hook templates"
```

---

### Task 20: Update claude-init — mode flag support

**Files:**
- Modify: `bin/claude-init`

**Step 1: Read current argument parsing**
```bash
head -30 bin/claude-init
grep -n 'TEMPLATE_TYPE\|^1\}' bin/claude-init | head -10
```

**Step 2: Add --product and --lib flags alongside existing type arg**

After `TEMPLATE_TYPE="${1:-}"`, add:
```bash
PROJECT_MODE="internal"  # default

# Parse additional flags
for arg in "$@"; do
    case "$arg" in
        --product) PROJECT_MODE="product" ;;
        --lib)     PROJECT_MODE="lib" ;;
    esac
done
```

**Step 3: Use PROJECT_MODE when copying pipeline-status template**

In the CLAUDE.md setup section, after copying the template:
```bash
# Copy mode-appropriate pipeline-status
STATUS_TEMPLATE="$KIT_DIR/templates/pipeline-status-${PROJECT_MODE}.md"
[[ -f "$STATUS_TEMPLATE" ]] || STATUS_TEMPLATE="$KIT_DIR/templates/pipeline-status-internal.md"
mkdir -p "$PROJECT_DIR/tasks"
sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s/{{KIT_VERSION}}/$(cat "$KIT_DIR/VERSION" 2>/dev/null || echo unknown)/g" \
    "$STATUS_TEMPLATE" > "$PROJECT_DIR/tasks/pipeline-status.md"
echo "[+] Pipeline status → tasks/pipeline-status.md (mode: $PROJECT_MODE)"
```

**Step 4: Verify**
```bash
bash -n bin/claude-init && echo "ok: syntax" || echo "FAIL: syntax error"
grep -q 'PROJECT_MODE\|--product\|--lib' bin/claude-init && echo "ok: flags" || echo "FAIL"
```

**Step 5: Commit**
```bash
git add bin/claude-init
git commit -m "feat(claude-init): add --product and --lib mode flags"
```

---

## Track E: Public Repo Files (for kit itself)

### Task 21: Create CONTRIBUTING.md, SECURITY.md, CHANGELOG.md

**Files:**
- Create: `CONTRIBUTING.md`
- Create: `SECURITY.md`
- Create: `CHANGELOG.md`

**Step 1: Write CONTRIBUTING.md**

Key sections: how to add a lint plugin (TIER= variable, detect logic, generate output), how to submit a new skill (SKILL.md frontmatter format), how to contribute a CLAUDE.md template improvement, code style (shellcheck must pass), PR process.

**Step 2: Write SECURITY.md**

Key sections: supported versions, how to report a vulnerability (GitHub private advisory or email), what constitutes a security issue in this repo, response SLA.

**Step 3: Write CHANGELOG.md**
```markdown
# Changelog

All notable changes to claude-onboarding-kit are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [Unreleased]

### Added
- Mode-based project lifecycle pipeline (Internal Tool / Product / Open Source Library)
- 8 new skills: create-tech-spec, create-risk-log, create-qa-plan, create-adr,
  create-retrospective, create-mrd, create-roadmap, create-release-plan
- Pipeline status tracking (tasks/pipeline-status.md)
- Kit version tracking (VERSION file)
- goal-reflection and improvement-loop hook templates
- AGENTS.md template
- gitleaks.toml allowlist starter
- claude-init --product and --lib mode flags

### Changed
- lesson-check.sh archived — lessons-db is now canonical anti-pattern scanner
- /setup-repo Phase 7 updated to use lessons-db scan + scope inference
- CLAUDE.md templates overhauled with lessons rules, Code Factory, lean gate

### Removed
- lesson-check.sh from scripts/ (archived to _archived/)
```

**Step 4: Commit all 3**
```bash
git add CONTRIBUTING.md SECURITY.md CHANGELOG.md
git commit -m "docs: add CONTRIBUTING.md, SECURITY.md, CHANGELOG.md for public release"
```

---

### Task 22: Create examples/

**Files:**
- Create: `examples/node/README.md`
- Create: `examples/python/README.md`

**Step 1: Write minimal examples**

Each example shows the expected output of `/setup-repo` for that project type:
- Directory structure produced
- CLAUDE.md sections visible
- Commands that work after setup

**Step 2: Commit**
```bash
git add examples/
git commit -m "docs: add examples/ — node and python post-setup-repo output"
```

---

## Final Verification

### Task 23: Run validation harness + fix any remaining failures

**Step 1: Run full validation**
```bash
bash tests/validate.sh
```
Expected: all `[ok]` — 0 failures.

**Step 2: Run install in temp directory to verify end-to-end**
```bash
TMPDIR=$(mktemp -d)
KIT_DEST="$TMPDIR/.claude/kit" bash install.sh
ls "$TMPDIR/.claude/kit/skills/"
ls "$TMPDIR/.claude/skills/"
# Should show all 9 skills installed
```

**Step 3: Update README to reflect new capabilities**
- Add mode-based pipeline section
- Update command list
- Update features table

**Step 4: Update kit's CLAUDE.md**
- Update command list (add new skills)
- Note lesson-check archival

**Step 5: Final commit**
```bash
git add README.md CLAUDE.md
git commit -m "docs: update README + CLAUDE.md for v1.0 capabilities"
```

**Step 6: Tag**
```bash
git tag v1.0.0
git push && git push --tags
```

---

## Task Order Summary

```
Task 0  (harness)     → independent, do first
Task 1-4 (Track A)    → sequential, unblocks nothing else
Task 5-7 (Track B)    → sequential with each other, after Task 0
Task 8-15 (Track C)   → fully parallel with each other and Track B
Task 16 (templates)   → after Task 5-7 complete (mode pipeline needed)
Task 17-18 (infra)    → parallel with Track C
Task 19 (install.sh)  → after Tasks 1, 8-15, 17-18 complete
Task 20 (claude-init) → after Task 18 (pipeline-status templates)
Task 21-22 (public)   → parallel, any time
Task 23 (verify)      → last
```
