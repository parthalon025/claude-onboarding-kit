---
name: create-adr
description: Create an Architecture Decision Record — documents a significant technical decision with context, options considered, and rationale. Output: docs/decisions/NNNN-title.md
---

# Create Architecture Decision Record (ADR)

Produces `docs/decisions/NNNN-title.md`. Use for any non-obvious technical
decision so future sessions (and future you) understand *why*, not just *what*.

## Arguments
$ARGUMENTS — decision title or description

## Process

### Step 1: Determine next ADR number
```bash
ls docs/decisions/ 2>/dev/null | grep -E '^[0-9]{4}' | wc -l
# Next number = count + 1, zero-padded to 4 digits
```

### Step 2: Generate ADR

```markdown
# ADR-NNNN: [Decision Title]

**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-XXXX
**Date:** YYYY-MM-DD
**Deciders:** [project / Claude]

## Context

[1-2 paragraphs: what situation forced this decision? What constraints exist?
What would happen if we don't decide now?]

## Decision

[1 paragraph: what we decided to do, stated plainly]

## Options Considered

| Option | Pros | Cons |
|--------|------|------|
| **[Chosen]** | [pros] | [cons] |
| [Alternative 1] | [pros] | [cons] |
| [Alternative 2] | [pros] | [cons] |

## Rationale

[Why the chosen option wins given the context and constraints]

## Consequences

**Positive:** [what gets better]
**Negative:** [what gets harder or is now ruled out]
**Risks:** [what could go wrong with this decision]

## Review Trigger

Revisit this decision if: [specific conditions — e.g., "traffic exceeds 10k req/s"]
```

### Step 3: Save file
```bash
mkdir -p docs/decisions
# Save to docs/decisions/NNNN-title.md
```
