---
name: create-tech-spec
description: Generate a technical specification document — architecture decisions, API contracts, data models, infrastructure constraints, performance requirements. Separate from the implementation plan (writing-plans). Output: docs/plans/tech-spec.md
---

# Create Technical Specification

Produces `docs/plans/tech-spec.md` — the engineering contract that explains
*why* the system is designed the way it is, not *how* to implement it task-by-task.

## Arguments
$ARGUMENTS — optional: feature or component name

## Process

### Step 1: Gather context
Ask (one at a time if not obvious from codebase):
1. What system/component is this spec for?
2. What are the key external interfaces (APIs, queues, databases, user-facing surfaces)?
3. What are the non-functional requirements (latency, throughput, availability, scale)?
4. What alternatives were considered and why rejected?

### Step 2: Generate spec

Output to `docs/plans/tech-spec.md`:

```markdown
# Technical Specification — [Component]

**Status:** Draft | Approved | Superseded
**Date:** YYYY-MM-DD
**Author:** [project name]

## Problem Statement
[One paragraph: what problem this solves and why it matters]

## Scope
**In scope:** [bullet list]
**Out of scope:** [bullet list]

## Architecture

### Overview
[2-3 paragraph description + ASCII diagram if helpful]

### Components
| Component | Responsibility | Technology |
|-----------|---------------|------------|
| ... | ... | ... |

### Data Flow
[Step-by-step: input → processing → output]

### Data Models
[Key entities, fields, types, constraints]

## API Contracts
[Endpoints/interfaces with request/response shapes]

## Infrastructure
[Hosting, storage, networking, environment variables needed]

## Non-Functional Requirements
| Requirement | Target | Measurement |
|-------------|--------|-------------|
| Latency | < 200ms p99 | ... |
| ... | ... | ... |

## Security Considerations
[Auth, authz, data sensitivity, attack surface]

## Alternatives Considered
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| [chosen] | ... | ... | Selected |
| [rejected] | ... | ... | Rejected because ... |

## Open Questions
- [ ] [question with owner and deadline]
```

### Step 3: Save and confirm
Save to `docs/plans/tech-spec.md`. Ask: "Does this spec look right? Any sections to expand?"

### Step 4: Update pipeline-status.md
```bash
# Mark Tech Spec as complete in tasks/pipeline-status.md
sed -i 's/| Tech Spec |.*⬜.*/| Tech Spec | docs\/plans\/tech-spec.md | ✅ | '"$(date +%Y-%m-%d)"' |/' tasks/pipeline-status.md
```
