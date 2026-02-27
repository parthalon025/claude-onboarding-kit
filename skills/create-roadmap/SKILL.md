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
