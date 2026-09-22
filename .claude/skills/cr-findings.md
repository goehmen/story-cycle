# Code Review Findings — Output Format Skill

## When to use this skill

Stage 4 (Independent Review) of the Story Cycle workflow. After running `/bmad-code-review`, follow this skill's spec when writing the "Code Review Findings" section to the spec file at `_bmad-output/implementation-artifacts/spec-<x-x-slug>.md`.

This skill is also referenced by Stage 5 (Fix Issues), which reads findings written in this format.

## Do not touch the Review Triage Log

`bmad-build` writes its own `## Review Triage Log` into the same spec file at step 04. That section is build's record of its three internal review layers: one row per finding, with a verdict of high, medium, low, `false`, or `maybe-false`, plus evidence.

**Never modify, merge into, or reformat `## Review Triage Log`.** It is build's output, not yours. Two findings records coexist in one file by design: build's internal review and this independent pass. Keeping them separate is what makes the Stage 4 experiment measurable.

## Findings section placement

Append the findings section to the end of the spec file's body, as a top-level H2 heading so it sits as a sibling of `## Review Triage Log`:

```markdown
## Code Review Findings
```

If a "Code Review Findings" section already exists from a previous review pass, append a new dated subsection under it rather than overwriting. Use H3 for the dated subsection:

```markdown
## Code Review Findings

### 2026-09-20 — initial review

### 2026-09-21 — repeat pass after fixes
```

## Per-finding format

Each individual finding uses an H4 heading and the following fields. All fields are required:

```markdown
#### H1 — <short title>
**File:** <path/to/file.ext:line>
**Severity:** High
**New vs build:** new
**Description:** <what's wrong; one to three sentences>
**Recommended fix:** <how to fix; one to three sentences>
**Status:** unresolved
```

### The `New vs build` field

Compare each finding against the rows already in `## Review Triage Log`. Record one of:

- `new` — build's three layers did not raise this.
- `duplicate of <verdict> row: <short description>` — build raised the same claim. Name the row.

This field exists to make the Stage 4 experiment countable. The whole question is which findings this stage produces that build's internal review did not, and that number is unrecoverable after the fact if nobody records it during the pass. Keep the field permanently once the experiment resolves; it costs one line and it is the ongoing evidence that this stage earns its cost.

## Severity rules

Three severities, used consistently:

- **High (H)** — security vulnerabilities, data loss risks, critical regressions, broken contracts, anything that would block a production deploy.
- **Medium (M)** — design issues, maintainability concerns, performance regressions that don't block deploy, missing error handling, gaps in test coverage that risk regression.
- **Low (L)** — style, naming, minor refactors, low-risk improvements, docstring gaps.

When uncertain between two severities, escalate. A finding marked High that turns out to be Medium is recoverable in a repeat pass. A finding marked Low that should have been High may ship.

Note that build's triage uses a different vocabulary on purpose: it discards its reviewers' severity grades and renders high, medium, low, `false`, or `maybe-false` after verifying each claim at the cited location. Do not try to reconcile the two scales. Record your own severity and use `New vs build` to link across.

## ID convention

IDs combine the severity letter with a sequential number per severity, starting at 1. Examples:

- First High finding: `H1`. Second: `H2`.
- First Medium: `M1`. Second: `M2`.
- First Low: `L1`. Second: `L2`.
- First decision-needed finding: `D1`. Second: `D2`.

IDs are stable across the story's review cycles. If a finding gets resolved and a repeat pass surfaces the same issue, reuse the same ID with an updated status (`resolved` → `unresolved` again with a note explaining the regression).

New findings introduced during a repeat pass take the next available number for their severity.

## Status values

Four values:

- `unresolved` — finding not yet addressed.
- `resolved` — fix applied; verified in a repeat pass (or pending one).
- `deferred` — finding intentionally not addressed in this story; document the rationale in a `**Deferral note:**` field below `Status`.
- `decision-needed` — an ambiguous choice that requires the human. Use the `D` ID prefix. This maps to `bmad-code-review`'s own `decision_needed` triage route, which is available only when `review_mode = full`, meaning only when the spec was supplied. `bmad-build` has no equivalent route, so a `D` finding is by definition something this stage produced and build could not.

Stage 5 (Fix Issues) updates `Status` from `unresolved` to `resolved` or `deferred` per finding. A `decision-needed` finding is answered by the human, not by the fix session; record the answer in a `**Decision:**` field, then set the status accordingly.

A repeat pass appends a verification line under each finding it confirms resolved:

```markdown
**Verified:** 2026-09-21 — fix confirmed by repeat pass.
```

## This stage sets `done`

`bmad-code-review` step-04 sets `new_status = done` only when every `decision-needed` and `patch` finding is resolved, and no unresolved `high` or `medium` remains. Nothing later in the cycle syncs story status.

So when this pass produces real findings, the story stays at `review`. After Stage 5 resolves them, run a short repeat pass here to verify and close. A story left at `review` blocks the next story's continuity and blocks the epic retrospective.

Confirm after each pass:

```bash
grep "<story-slug>" _bmad-output/implementation-artifacts/sprint-status.yaml
```

## When to stop reviewing

Stop when the findings are mostly low-value notes about exotic corner cases. That is accidental complexity, not quality.

Non-trivial findings on a third pass usually mean something is wrong upstream of this change: a weak spec, a contradiction, or ambiguity in the rules. Fix that instead of running another pass, and note it for the epic retrospective.

## Worked example

```markdown
## Code Review Findings

### 2026-09-20 — initial review

#### H1 — Validation bypassed on the bulk import path
**File:** src/import/bulk.ts:88
**Severity:** High
**New vs build:** new
**Description:** Single-record creation validates against the schema, but the bulk path constructs records directly and skips it. Invalid rows reach the database.
**Recommended fix:** Route the bulk path through the same validator the single-record path uses, rather than duplicating the checks.
**Status:** unresolved

#### D1 — Deactivation leaves the account row but clears the linked credential
**File:** src/account/deactivate.ts:34
**Severity:** Medium
**New vs build:** new
**Description:** Deactivation soft-invalidates the account row and deletes the stored credential. Reactivation then needs a fresh credential write against an existing row. The spec does not say whether that is an upsert on the existing row or a new row, and both are defensible.
**Recommended fix:** Human decision required before this path is final.
**Status:** decision-needed

#### M1 — Missing test for the empty-result case
**File:** src/adapters/reports/list.test.ts
**Severity:** Medium
**New vs build:** duplicate of medium row: "no coverage for empty provider response"
**Description:** No test asserts behavior when the provider returns zero records.
**Recommended fix:** Add a case asserting the adapter returns an empty array rather than throwing.
**Status:** unresolved
```

After Stage 5:

```markdown
#### H1 — Validation bypassed on the bulk import path
[...]
**Status:** resolved

#### D1 — Deactivation leaves the account row but clears the linked credential
[...]
**Decision:** 2026-09-20 — upsert on the existing row, keyed on (account_id, provider), per AGENTS.md. No new row.
**Status:** resolved

#### M1 — Missing test for the empty-result case
[...]
**Status:** deferred
**Deferral note:** Build's triage already routed this to defer with the same reasoning. Tracked in deferred-work.md.
```
