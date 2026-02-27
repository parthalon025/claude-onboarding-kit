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
