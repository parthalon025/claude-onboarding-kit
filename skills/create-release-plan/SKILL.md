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
