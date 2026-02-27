---
name: block-force-push
enabled: true
event: bash
pattern: git\s+push\s+.*--force|git\s+push\s+-f
action: block
---

**Force push blocked.**

Force pushing rewrites remote history and can destroy teammates' work.

If you truly need this:
- Use `--force-with-lease` instead (safer)
- Never force push to main/master
- Confirm with the user before proceeding
