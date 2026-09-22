# Plan Gate: Spec Validation Checklist Skill

## When to use this skill

Two moments in the Story Cycle, same checklist:

1. **Stage 2, at CHECKPOINT 1.** `bmad-build` presents the spec for approval. Apply this checklist before choosing "Approve and stop." This is the highest-value human moment in the cycle: everything inside `<frozen-after-approval>` locks once you approve, and only a human can change it afterward.
2. **Stage 2b, as a fresh-session pass.** After approval, validate the written spec from a separate session before implementation begins.

Invoke via the Stage 2b prompt: `follow .claude/skills/plan-gate.md to validate _bmad-output/implementation-artifacts/spec-<x-x-slug>.md`.

**Argument resolution (for ad-hoc invocations, e.g. "check the spec for 2-3"):**

- No argument: resolve to the most recently modified file in `_bmad-output/implementation-artifacts/` matching `spec-[0-9]*-*.md` (exclude `epic-*`, `deferred-work.md`, `sprint-status.yaml`).
- An ID like `2-3`: resolve to `_bmad-output/implementation-artifacts/spec-2-3-*.md` (glob; if multiple match, ask which).
- A full path: use directly. This is what the automated Stage 2b terminal supplies, derived from the branch name.
- Always confirm the resolved file path in your first sentence so the user can correct you if wrong.

## Required session conditions

- **Fresh session.** The validator must not share context with the build session that wrote the spec; shared context biases the validator toward confirming the author's reasoning. At CHECKPOINT 1 this is not possible, so apply the checklist yourself and use Stage 2b for the independent pass.
- **Model diversity.** Stage 2 uses the stronger model; Stage 2b uses a different one. Different models on different sessions, by design.
- **Codebase access.** The validator must read the files the Code Map references, to confirm they exist and contain what the spec claims.

---

## Prompt

```
You are a senior technical reviewer performing spec validation. A spec has just been written by bmad-build. Your job is to read the spec and evaluate whether it is ready for an implementation agent to execute, not to implement it yourself.

Read the spec at [PATH TO SPEC FILE] and evaluate it against every item in the following checklist. For each item, mark it PASS, FAIL, or N/A with a one-line explanation. At the end, give an overall verdict: READY TO IMPLEMENT or NEEDS REVISION, and list any required changes.

Checklist:

Frontmatter and routing
- `route:` is `dispatch`, not `oneshot`. The one-shot route skips CHECKPOINT 1 entirely and drops review from three layers to one.
- `status:` is `draft` (at CHECKPOINT 1) or `ready-for-dev` (at Stage 2b). Any other value means the spec is not at the gate.
- Every file listed in frontmatter `context:` exists and is relevant.

Open Questions
- The Open Questions section is empty, or every question carries a recorded human answer.
- No answer was invented. If an answer reads like the agent's own inference rather than a decision, that is a FAIL.
- No answer opens a new gap that is left unaddressed.

Frozen block
- Every statement inside `<frozen-after-approval>` is a decision, not an assumption. A sentence that could be prefixed with "presumably" is a FAIL.
- The goal is a single user-facing goal, not two shipped together.
- Scope-out is explicit: what the story deliberately does NOT do is stated, separately from anything deferred to `deferred-work.md`.
- Acceptance criteria are in Given/When/Then format and independently testable.
- Acceptance criteria cover the happy path, at least one error or edge case, and at least one regression case for existing behavior.
- No acceptance criterion is internally contradictory or duplicates another.
- Nothing in the frozen block contradicts a constraint in AGENTS.md.

Code Map
- Every path the Code Map names exists. A path that does not resolve is an automatic FAIL, not a guess.
- Every symbol, function, or export the Code Map names exists in the file it names.
- The Code Map is specific enough that an implementation agent could work from it without re-investigating the codebase.
- What to reuse and what not to touch are both stated, not just one.

Tasks and verification
- Every acceptance criterion maps to at least one task.
- Tasks are specific enough to execute without further design decisions.
- Tasks are ordered sanely: schema before code that depends on it, tests after the code they cover.
- If the story requires manual configuration after deploy (a vendor dashboard setting, an env var, a secret store entry), it is a named task or post-merge action, not buried in prose.
- If the story integrates a new or extended third-party service, a task confirms the specific features required are available on that vendor's actual current tier, verified before the spec was finalized rather than discovered mid-implementation.
- If the frozen block declares an I/O and Edge-Case Matrix, every row has a corresponding verification step.

Scope and size
- The spec is between 900 and 1600 tokens. Under 900 risks ambiguity; over 1600 risks context rot in the implementation agent.
- The work is completable in a single focused session: roughly 500 changed lines excluding tests, across a small handful of files.
- No blocking dependency on an unfinished story in the current sprint.
- Nothing duplicates work already merged to main.
- No silent assumption that an unmerged PR lands first.

Output format:

## Plan Gate: [Story ID and Title]

### Checklist Results
[Each item: PASS / FAIL / N/A, one-line note]

### Verdict
READY TO IMPLEMENT  /  NEEDS REVISION

### Required Changes Before Proceeding
[List only items that are FAIL, specific and actionable]

If the verdict is READY TO IMPLEMENT, say so and stop. Do not suggest improvements beyond what is required for the spec to be implementable. If the verdict is NEEDS REVISION, list only the specific changes required. Do not rewrite the spec.
```

---

## Implementation Notes

- **The Code Map is where this checklist earns its keep.** Read the actual source files it references; do not take the spec's word for it. A broken reference (file does not exist, or does not contain the named symbol) is the single most common cause of an implementation agent going wrong, and it is invisible unless someone checks.
- **Manual configuration steps are the most commonly missed item.** If a story needs a secret store entry, an env var, or a provider dashboard setting, that must be a named task, not discovered post-merge.
- **Vendor tier verification is not theoretical.** Third-party services have tier and quota boundaries that are cheap to check before a spec is frozen and expensive to hit mid-implementation. One project lost roughly six hours to three separate paywall discoveries that this check would have caught.
- State the resolved spec file path in your first sentence, so the user can correct you if the wrong file was picked up.

**Validator guardrails:**

- Do not invent checklist items beyond what is listed in the Prompt above or the project-specific section below. The checklist is fixed; project-specific additions come only from this file.
- Distinguish PASS from N/A precisely. PASS means the item is satisfied. N/A means the item does not apply to this story, for example no schema change means the ordering check is N/A. Do not mark something N/A because it is inconvenient to check.
- Be specific in FAIL reasons. "The Code Map is vague" is not enough. Name the path or symbol and say what is missing.
- Do not rewrite the spec. Report FAILs and what is required to fix them.
- At Stage 2b, remember that `<frozen-after-approval>` is locked. A FAIL inside the frozen block means a decision the human recorded was wrong, and only the human can change it. Say so explicitly rather than proposing an edit.

---

## Recommended Testing Checklist Items

Carried over from prior project retrospectives. Stack-agnostic and expensive to re-learn. Each applies to what the spec *specifies*, not to code that does not exist yet: a spec that names no tests fails the relevant item rather than skipping it.

- **Hard assertions.** No test the spec describes is guarded by `if`, `.or()`, or skip-if-absent logic. Every step has a deterministic expected outcome. A spec that says "verify the response looks reasonable" is a FAIL.
- **Mock negative-case rule.** Every test the spec names that mocks data is paired with one asserting what should *not* appear in the empty or negative case.
- **Zero-state rule.** Every computed display value the story introduces (a formatted figure, a percentage, a date, a balance) has a named test where the primary input is `0`, `null`, or empty.
- **No vacuous tests.** Fixtures the spec describes reflect real provider response shapes, not placeholder values that pass without verifying behavior. A fixture invented from an interface definition rather than from an actual sandbox response is a FAIL.
- **No retroactive integration tests.** The spec proposes E2E for critical flows, contract tests for external APIs, and unit tests for pure logic. A task reading "add integration tests for coverage" is a FAIL.

---

## Project-Specific Checklist Items

Replace this section with checks specific to your project.

Do not restate constraints that already live in `AGENTS.md`. Check *against* them instead. `AGENTS.md` loads in every session, so duplicating it here creates two copies that drift, and neither gets pruned automatically.

Candidates worth considering:

- **AGENTS.md conformance.** The spec violates no constraint in the AGENTS.md policy or conventions sections. Name the specific constraint if it does.
- **Architecture boundaries.** If the story crosses a layer or port boundary your architecture defines, the spec respects it. A raw third-party SDK client is imported only where your architecture permits.
- **Data protection.** If the story creates a table, the spec enables row-level security or your equivalent in the same migration.
- **Privileged connections.** No task instantiates an elevated database role or service credential outside the modules your architecture confines it to.
- **Secrets.** No real secret value appears anywhere in the spec, including in example env blocks. Key names with placeholders only.
- **Test framework.** The spec names specific test file paths to add or modify and does not propose replacing the framework. Before the scaffold story lands, this is N/A.
- **Spec file conventions.** The spec lives where your project keeps them, named to your convention, and your tracking file has a matching entry.
- **Open issues check.** If issues exist for the touched area, they are called out, either addressed or explicitly scoped out with a reason.

The general principle: any constraint you can check mechanically should eventually become a test or a lint rule rather than a checklist item. A rule in `AGENTS.md` is never pruned on its own authority, but a rule enforced by a tool can be deleted from the file entirely, which frees context budget that every review layer of every story otherwise pays for.

---

## Workflow Position

```
bmad-build steps 01-02  ->  CHECKPOINT 1 (this checklist)  ->  Stage 2b (this checklist, fresh session)
        Stage 2                   Approve and stop                     independent pass
                                                                               |
                                                                               v
                                                             bmad-build step 03  ->  bmad-code-review
                                                                   Stage 3               Stage 4
```
