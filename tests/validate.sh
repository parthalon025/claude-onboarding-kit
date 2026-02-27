#!/usr/bin/env bash
# Validates kit structure — run before and after changes
set -euo pipefail
PASS=0; FAIL=0
check() { local desc="$1" result="$2"
  if [[ "$result" == "ok" ]]; then echo "[ok] $desc"; PASS=$((PASS+1))
  else echo "[!!] $desc"; FAIL=$((FAIL+1)); fi }

# Core files
check "install.sh exists" "$([ -f install.sh ] && echo ok || echo fail)"
check "uninstall.sh exists" "$([ -f uninstall.sh ] && echo ok || echo fail)"
check "bin/claude-init exists" "$([ -f bin/claude-init ] && echo ok || echo fail)"
check "skills/setup-repo/SKILL.md exists" "$([ -f skills/setup-repo/SKILL.md ] && echo ok || echo fail)"

# Templates
for t in node python general; do
  check "templates/CLAUDE.md.$t exists" "$([ -f "templates/CLAUDE.md.$t" ] && echo ok || echo fail)"
done

# lesson-check archived (not in scripts/)
check "lesson-check NOT in scripts/" "$([ ! -f scripts/lesson-check.sh ] && echo ok || echo fail)"

# New skills present
for s in create-tech-spec create-risk-log create-qa-plan create-adr \
          create-retrospective create-mrd create-roadmap create-release-plan; do
  check "skills/$s/SKILL.md exists" "$([ -f "skills/$s/SKILL.md" ] && echo ok || echo fail)"
done

# New hooks
for h in goal-reflection improvement-loop; do
  check "hooks/$h.sh exists" "$([ -f "hooks/$h.sh" ] && echo ok || echo fail)"
done

# Template sections present
for t in node python general; do
  f="templates/CLAUDE.md.$t"
  check "$t: has Lessons-Derived Rules" "$(grep -q 'Lessons-Derived Rules' "$f" && echo ok || echo fail)"
  check "$t: has Code Factory Workflow" "$(grep -q 'Code Factory Workflow' "$f" && echo ok || echo fail)"
  check "$t: has Lean Gate" "$(grep -q 'Lean Gate' "$f" && echo ok || echo fail)"
  check "$t: has Scope Tags" "$(grep -q 'Scope Tags' "$f" && echo ok || echo fail)"
  check "$t: has Skills section" "$(grep -q '## Skills' "$f" && echo ok || echo fail)"
  check "$t: has Workflow Pipeline" "$(grep -q 'Workflow Pipeline' "$f" && echo ok || echo fail)"
  check "$t: no lesson-check reference" "$(grep -qv 'lesson-check' "$f" && echo ok || echo fail)"
done

# setup-repo skill
f="skills/setup-repo/SKILL.md"
check "setup-repo: has mode question" "$(grep -qi 'internal tool\|product\|open source' "$f" && echo ok || echo fail)"
check "setup-repo: uses lessons-db not lesson-check" \
  "$(grep -q 'lessons-db' "$f" && ! grep -q 'lesson-check' "$f" && echo ok || echo fail)"
check "setup-repo: has Phase 9 (draft artifacts)" "$(grep -q 'Phase 9' "$f" && echo ok || echo fail)"
check "setup-repo: has Phase 11 (security gate)" "$(grep -q 'Phase 11' "$f" && echo ok || echo fail)"

# Public files
for f in CONTRIBUTING.md SECURITY.md CHANGELOG.md; do
  check "$f exists" "$([ -f "$f" ] && echo ok || echo fail)"
done

# gitleaks allowlist
check "gitleaks.toml exists" "$([ -f gitleaks.toml ] && echo ok || echo fail)"

# AGENTS.md template
check "templates/AGENTS.md exists" "$([ -f templates/AGENTS.md ] && echo ok || echo fail)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
