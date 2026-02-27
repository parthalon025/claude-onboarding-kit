---
name: warn-dangerous-commands
enabled: true
event: bash
pattern: rm\s+-rf|chmod\s+777|dd\s+if=|mkfs|>\s*/dev/
action: warn
---

**Dangerous command detected.**

Verify the target path is correct before proceeding. Consider:
- Is the path scoped narrowly enough?
- Could a typo cause data loss?
- Is there a safer alternative?
