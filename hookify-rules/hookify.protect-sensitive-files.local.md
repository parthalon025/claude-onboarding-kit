---
name: protect-sensitive-files
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.env$|\.env\.|credentials|\.pem$|\.key$|secret
action: warn
---

**Editing a sensitive file.**

- Do NOT add secrets, API keys, or tokens directly
- Ensure this file is in `.gitignore`
- Use environment variables or a secrets manager instead
