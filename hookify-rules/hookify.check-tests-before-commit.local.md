---
name: check-tests-before-commit
enabled: true
event: bash
pattern: git\s+commit
action: warn
---

**Committing code — pre-commit checklist:**

- Have you run the test suite and confirmed it passes?
- Have you run the linter?
- Are you committing only the intended files (not using `git add .`)?
- Is the commit message descriptive and focused on "why"?
