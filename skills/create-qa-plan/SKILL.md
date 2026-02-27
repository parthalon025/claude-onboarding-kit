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
```text

### Step 3: Update pipeline-status.md
```bash
sed -i 's/| QA Plan |.*⬜.*/| QA Plan | docs\/product\/qa-plan.md | ✅ | '"$(date +%Y-%m-%d)"' |/' tasks/pipeline-status.md
```
