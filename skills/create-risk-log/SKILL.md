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
