# Security Policy

## Supported Versions

Only the latest release on the `main` branch receives security fixes. Older tags are not backported.

| Version | Supported |
|---------|-----------|
| Latest (`main`) | Yes |
| Older tags | No |

---

## Reporting a Vulnerability

**Do not open a public GitHub Issue for security vulnerabilities.**

Report vulnerabilities via GitHub's private Security Advisory mechanism:

1. Go to the repository on GitHub
2. Click **Settings** > **Security** > **Advisories**
3. Click **Report a vulnerability**
4. Fill in the advisory form with a description, reproduction steps, and impact assessment

If you are unable to use GitHub Security Advisories, contact the maintainer directly via the email address in the Git commit history.

Include the following in your report:

- A clear description of the vulnerability
- Steps to reproduce (minimal reproduction preferred)
- The potential impact (what an attacker could do)
- Any suggested fix or workaround you have identified

---

## What Constitutes a Security Issue in This Repository

This kit generates files, runs scripts, and scaffolds new projects. The following categories are in scope for security reports:

**Hardcoded secrets in templates**
Any template in `templates/` that contains a hardcoded credential, token, API key, or other secret value — even as a placeholder example that could be mistakenly left in place.

**Path traversal in install scripts**
Any shell script in `install.sh`, `uninstall.sh`, `bin/claude-init`, or `scripts/` that constructs file paths from user input without sanitization, allowing an attacker to read or write files outside the intended target directories.

**Privilege escalation**
Any script that invokes `sudo`, changes file ownership, or modifies system-level paths when those operations are not required for the stated purpose of the script.

**Shell injection**
Any place where user-supplied input (project name, repository URL, arguments) is interpolated into a shell command without proper quoting or sanitization, enabling arbitrary command execution.

**Insecure defaults in generated CI/CD workflows**
Workflow templates in `workflows/` that grant excessive permissions (`write-all`), disable branch protection requirements, or expose secrets to untrusted code from pull requests.

**Out of scope:** Vulnerabilities in third-party tools installed by `lint-install` plugins (report those upstream to the respective tool maintainers).

---

## Response SLA

| Severity | Acknowledge | Fix |
|----------|-------------|-----|
| Critical (RCE, credential exposure) | 2 business days | 14 calendar days |
| High (path traversal, privilege escalation) | 2 business days | 21 calendar days |
| Medium / Low | 5 business days | Next release cycle |

After acknowledging a report, we will provide a fix timeline and keep you informed of progress. We will credit reporters in the release notes unless you prefer to remain anonymous.
