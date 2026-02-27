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
