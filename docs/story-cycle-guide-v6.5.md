# Claude Code: Story Cycle - End-to-End Workflow Reference (v6.5)

Solo-founder development workflow for Claude Code with Claude Opus and Claude Sonnet, integrated with BMAD Method 6.12.0. Document version 6.5.

**Target:** BMAD Method 6.12.0, Claude Code, macOS.
**Source basis:** Verified against the `v6.12.0` tagged tree: skill sources under `src/bmm-skills/`, installer sources under `tools/installer/`, and the English documentation under `docs/`. Not the main branch, not release prose, not the live docs site (which tracks main).
**Status:** Not yet validated by real use. `[CALIBRATE]` markers are decisions to make once running stories gives you evidence. `[PROJECT]` markers need your own pipeline specifics filled in.

---

## The Cycle at a Glance

One story, start to finish. Everything after this is reference; this is the process.

The shape in one line: **select, plan, stop. Validate. Implement, stop. Review independently. Fix. Look at it. Ship. Clean up.**

Ten stages, six terminals, one VS Code window per story. Every stage is its own Claude Code session, killed when the stage ends. State lives in files, never in conversation history.

### Before the story

**Stage 1 — Select and Gate.** In any shell on `main`, Sonnet, `show sprint status`. It recommends a next story by mechanical priority ordering. You decide whether that is the right next thing. Close the session.

**Stage 0 — Setup.** Quit VS Code. `./scripts/story-start.sh 1-1 project-scaffold`. The script refuses if VS Code is running, `uv` is missing, a stale marker exists, the tree is dirty, you are not on `main`, or the branch already exists. It pulls, branches to `story/1-1-project-scaffold`, and opens a fresh VS Code window that spawns six named terminals. Each terminal prints its stage's commands and decisions in scrollback. None of them launches Claude Code; you do that when ready.

### The build half

**Stage 2 — Plan.** `plan` terminal, Opus, `/effort max`, Plan Mode **off**.

```
/bmad-build implement story 1-1 from the sprint status file. Do not take the one-shot route — write the full spec and present CHECKPOINT 1.
```

Build investigates the codebase and the planning artifacts, then stops at three points that are yours:

1. **Multi-goal split.** If it finds two independently shippable deliverables it halts and offers to split. Take the split unless the coupling risk is real; the leftover goes to `deferred-work.md` with evidence.
2. **Open Questions.** It presents intent gaps as numbered questions with options and consequences, then halts. It is forbidden from inventing answers. Yours get written into the spec as decisions and frozen.
3. **Token gate.** Over 1600 tokens it shows the count and offers a split. Take it.

Then **CHECKPOINT 1**. Apply `.claude/skills/plan-gate.md`. Choose **"Approve and stop"** — never "Approve and continue." The spec is now `ready-for-dev` and everything inside `<frozen-after-approval>` is locked to human edit only. Close the session.

**Stage 2b — Spec Review.** `spec-review` terminal, Sonnet, fresh context. Run `plan-gate.md` against the written spec, or for a spec with a real design tradeoff use `/bmad-party-mode --party anti-consensus-club --mode subagent`. The subagent mode is not optional; the default voices every persona through one model and manufactures agreement. Edit anything outside the frozen block. Close.

**Stage 3 — Implement.** `implement` terminal, Opus, `/effort max`. First:

```bash
touch .claude/.stage-6-active
```

That authorizes exactly one commit. Then:

```
/bmad-build resume _bmad-output/implementation-artifacts/spec-1-1-project-scaffold.md
```

Build reads `ready-for-dev` and jumps straight to implementation. It dispatches the work to a context-free subagent whose only source of truth is the spec, verifies every task against the actual diff rather than the subagent's report, runs three review layers in parallel, triages what they find, loops back as needed, then commits locally and stops.

Expect loopbacks. `intent_gap` returns to you because the root cause is inside the frozen block. `bad_spec` is fixed by build and logged. `patch` and `defer` are handled. Three loopbacks on one story means the spec was weak; note it for the retro.

At the end build offers to open a PR. **Decline.** Read `deferred-work.md`. Close the session.

### The check half

**Stage 4 — Independent Review.** `review` terminal, Sonnet, `think harder`. Never the `implement` terminal.

```
/bmad-code-review think harder
```

**Give it the spec.** That sets `review_mode = full`, which is what enables the Acceptance Auditor layer and the `decision_needed` route. Build has neither. That is the entire reason this stage exists, alongside the different model and a triage pass with no authorship attachment.

Write findings per `.claude/skills/cr-findings.md`, including the `New vs build:` field on every one. Never touch build's `## Review Triage Log`.

Stop repeating passes when findings are mostly low-value corner cases. Non-trivial findings on a third pass mean something upstream is wrong. Fix that instead.

**Stage 5 — Fix Issues.** `fix` terminal, Opus. Resolve what Stage 4 found. Scope is narrow: build already fixed what belonged to its own change. Over six findings, split into an H+M pass and an L pass. A `decision-needed` finding is answered by you, not by the session.

**Stage 6 — Walkthrough and Smoke.** `ops` terminal, Sonnet. `/bmad-walkthrough` gives a concern-ordered reading guide with clickable stops and two to five risk spots ordered by blast radius. It is human review, not agentic: no linters, no tests, no severities. At wrap-up it offers to push. Decline. Then smoke test by hand, guided by its Testing step.

### Ship and close

**Stage 7 — Commit.** Usually nothing to do; build already committed. If Stage 5 changed files, `touch .claude/.stage-6-active` again and make a separate `fix:` commit.

**Stage 8 — Push, PR, CI, Merge.** `ops` terminal, no agent role. Push the branch, open a PR with a quoted heredoc body, wait for green, smoke the preview, squash merge.

**Stage 9 — Cleanup.** `./scripts/story-cleanup.sh story/1-1-project-scaffold`. Deletes the branch (handling the squash case), clears the marker and scratchpad.

**At epic close, mandatory here:** `/bmad-retrospective -H <epic>`, then `bmad-project-context` in audit intent, then triage `deferred-work.md`. This framework maximizes isolation, so it maximizes the defect class isolation hides: architecture drift, the helper written twice, the file every session grew a little. The retrospective is the designed remedy for exactly that.

### The four things that go wrong

1. **Forgetting the marker before Stage 3.** Build does all the work, then its commit is refused. Costs a retry.
2. **Approve and continue at CHECKPOINT 1.** Collapses Stage 2 and Stage 3 into one session and loses the isolation the whole design is built on.
3. **Running code review in the `implement` terminal.** Same failure, worse: the review inherits the build's framing.
4. **Letting build take the one-shot route.** One review layer instead of three, and no checkpoint at all. The project override blocks it; say it in the prompt too.

---

## Contents

**Front matter**
- **The Cycle at a Glance** — read this first

**Part 1 - Setup and Approach**
- The BMAD 6.12 Phase 4 Chain
- Artifacts Build Produces
- Authorization Boundaries
- Session Architecture Principles, and Their Cost
- Agent Instruction Files
- Thinking Mode Quick Reference
- Plan Mode in v6.5
- What Stays Manual and Why
- Compaction Reference
- Mid-Session State
- Automation Surface
- BMAD Customization Surface
- VS Code Setup

**Part 2 - Full Story Cycle Workflow**
- Stage 0 Setup
- Stage 1 Select and Gate
- Stage 2 Plan
- Stage 2b Spec Review
- Stage 3 Implement
- Stage 4 Independent Review
- Stage 5 Fix Issues
- Stage 6 Walkthrough and Smoke
- Stage 7 Commit
- Stage 8 Push, PR, CI, Merge
- Stage 9 Cleanup and Epic Close

**Part 3 - Reference and Summary**
- Complete Flow Summary
- Build's Internal Triage, and Why Stage 4 Exists
- Compaction Risk by Stage
- Git Branch Workflow
- Quick Decision Rules
- Tips and Troubleshooting
- Generating a Shareable Version
- v7 Future Direction

---

# Part 1 - Setup and Approach

## The BMAD 6.12 Phase 4 Chain

As printed by the installed catalog:

```
Phase 4 - Ship
bmad-build (required)
  preceded by:  bmad-sprint-planning
  followed by:  bmad-code-review (optional, extra check)

  bmad-walkthrough            guided human review of a change/PR
  bmad-qa-generate-e2e-tests  automated test suite (after a build)
  bmad-retrospective          optional, end-of-epic lessons learned
```

Anytime tools: `bmad-spec`, `bmad-correct-course`, `bmad-sprint-planning` (status view), `bmad-project-context`, `bmad-review`, `bmad-advanced-elicitation`, `bmad-party-mode`, `bmad-customize`, `bmad-forge-idea`, `bmad-deep-recon`, `bmad-help`.

`bmad-build-auto` is also installed. Not used in v6.5; see v7 Future Direction.

**Build's five steps**, which Story Cycle wraps:

| Step | File | What it does |
|---|---|---|
| 01 | `step-01-clarify-and-route.md` | Resolves workflow state, compiles epic context, VCS sanity check, multi-goal check, sets `spec_file` |
| 02 | `step-02-plan.md` | Investigates, decides oneshot vs dispatch, writes spec, resolves Open Questions, **CHECKPOINT 1** |
| 03 | `step-03-implement.md` | Captures `baseline_commit`, dispatches implementation, stages `{diff_file}`, verifies tasks, matrix test audit |
| 04 | `step-04-review.md` | Runs review layers in parallel, triages, routes, loops back |
| 05 | `step-05-present.md` | Marks spec `done`, syncs sprint status to `review`, **creates the local commit**, presents |

Build resumes at a step determined by the spec's `status` frontmatter: `draft` to step-02, `ready-for-dev` or `in-progress` to step-03, `in-review` to step-04. That is what makes the Stage 2 / Stage 3 split work, and what makes a repeat review pass possible.

## Artifacts Build Produces

| Artifact | Path | Written by |
|---|---|---|
| Spec | `{implementation_artifacts}/spec-{slug}.md` | step-02. Slug leads with the tracking id: `spec-3-2-digest-delivery.md` |
| Deferred work ledger | `{implementation_artifacts}/deferred-work.md` | step-01, step-02, step-04. Append-only. |
| Epic context cache | `{implementation_artifacts}/epic-<N>-context.md` | step-01. Invalidated when any planning artifact is newer. |
| Sprint status | `{implementation_artifacts}/sprint-status.yaml` | step-03 sets `in-progress`; step-05 sets `review`. Comments preserved. |
| Test summary | `tests/test-summary.md` | `bmad-qa-generate-e2e-tests` |
| Unified diff | temp file, path in `{diff_file}` | step-03, rewritten in step-04. Layers read the file; diff text is never pasted into prompts. |

**Key spec sections:**

- `<frozen-after-approval>`: locked at CHECKPOINT 1. Only a human may change it.
- `## Code Map`: investigation output. Paths, symbols, what to reuse, what not to touch.
- `## Open Questions`: intent gaps. Must be empty before CHECKPOINT 1.
- `## Review Triage Log`: one row per finding, verdict plus evidence. Never dropped or merged.
- `## Spec Change Log`: appended on each `bad_spec` loopback.
- Frontmatter: `status`, `route`, `baseline_commit`, `review_loop_iteration`.

**This replaces v5's story file.** The v5 rule that findings live in the story file is preserved: `spec-{slug}.md` is the one cohesive lifecycle record.

## Authorization Boundaries

Build commits, once, at step-05: "If version control is available and the tree is dirty, create a local commit with a conventional message derived from the spec title." Step-05's rules say **NEVER auto-push**; step-03's say **No push. No remote ops.**

**The boundary rules:**

- Each stage ends when its work completes; the next stage begins when the user starts it.
- An agent never invokes another stage's actions.
- Build setting sprint status to `review` means "ready for code review." It does NOT authorize push or PR.
- "Tests pass" does NOT authorize push. Run Stage 4 instead.
- "All findings resolved" does NOT authorize push. Run Stage 6, then Stage 8.
- Build's local commit is authorized in advance, per run, by the marker. Nothing else is.

Each prohibition above names the permitted alternative. Keep that shape when writing these into `CLAUDE.md`; see "Agent Instruction Files."

**Marker semantics:** touched at **Stage 3 entry**, immediately before the implement session. Stage 2 writes only the spec and needs no authorization. One marker authorizes one commit; the post-commit hook clears it, so build cannot commit twice and a Stage 5 fix commit needs a fresh touch.

```bash
touch .claude/.stage-6-active   # authorizes exactly one commit
```

There is no `commit = false` key in `customize.toml`. Build only commits when the tree is dirty; suppressing it means fighting the skill. The marker approach is better.

**Three places an agent will offer to cross the boundary. Decline all three:**

| Where | What it offers |
|---|---|
| Build step-05 | "create a pull request (and push first if needed)" |
| Walkthrough step 5 | "approve means you are ready to push — the agent can help push and open a PR" |
| Code review final menu | "Start the next story — run `dev-story`" (stale text; that skill is deprecated and not installed) |

**Trigger phrases per action** (full list in CLAUDE.md):

| Action | User invocation that authorizes it |
|---|---|
| `git add` / `git commit` | "commit" or "commit the changes", or the Stage 3 marker touch |
| `git push` | "push" or "push to origin" |
| `gh pr create` | "open a PR" or "create the PR" |
| `gh pr merge` | "merge the PR" or "merge it" |
| `gh workflow run` | user explicitly names the workflow |

## Session Architecture Principles, and Their Cost

Non-negotiable. BMAD 6.12 supports all four natively.

- **One session per stage.** The docs are explicit: "Open a fresh chat in your AI IDE. Reusing a session from another workflow can mix contexts and confuse the run."
- **Persistent state lives in files.** `spec-{slug}.md` per story; `sprint-status.yaml` across stories; `deferred-work.md` for what was consciously not done.
- **Model diversity adds independence.** Build forces review subagents to the orchestrator's model capability, so diversity inside a build session requires overriding a layer to shell out. Across sessions it is free: Opus at Stage 2 and 3, Sonnet at Stage 4.
- **Fresh context per agent.** Build's reviewers are already context-free subagents. Triage is not: the orchestrator that wrote the spec renders the verdict on every finding, and is told to "reject any finding whose fix is to edit this build's spec."

**BMAD's own endorsement:** `step-04-review.md` has a fallback for runtimes without subagents. It writes each layer's prompt to disk with every file reference inlined, halts, and asks the human to "run each in a separate session (ideally a different LLM) and paste back the findings."

The same principle appears in party mode: "One model voicing five personas tends to make them agree. Separate agents keep their reasoning independent." That is why Stage 2b specifies `--mode subagent`.

**The cost, stated plainly.** From the retrospective docs: "Each story passed its own review in isolation, so the bugs that survive to this point are the ones isolation hides. Nine sessions each add a little to the same file, and none of them ever sees the oversized module they built together."

Story Cycle maximizes isolation, so it maximizes that failure mode. **Stage 9's retrospective is therefore mandatory in this framework**, not optional as BMAD frames it. It is the designed remedy for exactly the defect class this architecture creates.

## Agent Instruction Files

New in revision 3. This section governs `AGENTS.md`, `CLAUDE.md`, and the `.claude/skills/*.md` files Story Cycle depends on.

### The measured baseline

Repository instruction files, measured present versus absent: **no improvement in success rate and +20% inference cost.** Replicated on real repositories, with failures traced to implementation skill gaps rather than missing repository knowledge. In one study at scale, randomly generated rules matched expert-curated ones.

The reason is what those files usually contain: restatements of what the repository already holds. Structure, stack, architecture summaries. Agents read source better than summaries of source.

### The exception, and it is a large one

One controlled comparison against framework APIs absent from the model's training data:

| Configuration | Pass rate |
|---|---|
| No documentation | 53% |
| Reusable skill, unaided | 53% |
| Same skill, with explicit instructions to invoke it | 79% |
| **Compressed documentation index in `AGENTS.md`** | **100%** |

Same file format as the studies that found no improvement; opposite content. Knowledge the model did not have, rather than a restatement of the repo. The index was 8KB, compressed from 40KB with no loss in performance.

### The finding that applies to Story Cycle itself

**Agents often skip retrieval they have to choose.** The unaided skill above was never invoked in 56% of cases. Telling the agent explicitly to invoke it raised invocation above 95% and still capped at 79%, with outcomes swinging on small wording changes. In a separate test over a 709-page wiki, agents skipped the index and guessed page paths from the question instead.

Story Cycle runs on `.claude/skills/plan-gate.md`, `cr-findings.md`, and `scratchpad.md`, invoked by typing "also follow .claude/skills/X.md" at session start. **That is the 79% configuration, not the 100% one.** The explicit-invocation habit is the right mitigation and measurably better than leaving a skill unaided, but the ceiling is real.

Two mitigations, both worth doing:

1. **Keep the explicit invocation line** at every stage entry, as v5 did. It is what moves 56% to 95%.
2. **Put anything the agent must follow into `AGENTS.md` itself**, not into a skill it has to choose to fetch. A pointer out of `AGENTS.md` must name a trigger the agent can *observe* — a path, a file type, a concrete task — never one it must judge.

For Story Cycle that means the authorization boundary belongs inline in `AGENTS.md` and `CLAUDE.md`, not behind a pointer. The findings format and the plan-gate checklist can stay as skills, since a missed invocation there costs quality rather than safety.

### What earns a line

The test: *would removing this line change agent behavior?*

- **What a config file cannot say about running the project.** Not the obvious invocation, which lives in `package.json`. Which command is right when several look plausible, and the correction: integration tests need a service up first, CI runs a check the test script does not.
- **Policy the code cannot express.** Frozen paths, generated files, branch rules, security and compliance requirements.
- **Conventions that differ from ecosystem defaults.** Only the divergences.
- **Known pitfalls, from observed failure only.** A surprising scan finding becomes a question, never a line.
- **Cross-component rules and required versions.**
- **Negative constraints over positive guidance**, which measured better. A prohibition always names the permitted alternative.

### What stays out

What the code already says. Repo structure and file maps. Overview and tour documents, which are the ones measured to hurt. Ecosystem defaults. Anything included for being interesting. Style rules a formatter or linter should enforce. History and edit narration. Aspirational state.

### A working rule stays

**A policy or pitfall is removed only when what it is about is gone** — deleted, or now enforced by a tool — **or when a human removes it.** Absence of recent failures is never grounds: a working rule erases the evidence that it is still needed.

The same protection covers every instruction a human wrote. It goes only when stale, wrong, already enforced by a hook or check, harmful, contradictory, or approved for deletion as a line item. Never because it looks derivable.

This constrains the audit pass at epic close. Audit ends with the block smaller or equal, never larger, but human-written rules are protected from it.

### Two kinds of context

Implementation context (constraints, commands, conventions, pitfalls) belongs in the repository, must be tiny, and is loaded every session. That is what `bmad-project-context` owns.

Planning context (rationale, rejected approaches, ownership, domain meaning) belongs to a project or initiative, is consulted in bursts, and goes stale in months rather than hours. BMAD describes this as "a different capability, and it is coming separately."

**This guide is planning context.** It does not belong in `AGENTS.md`. Keep it at `docs/workflow/` and reference it from nowhere the agent loads automatically.

### `CLAUDE.md` imports rather than duplicates

`CLAUDE.md` carries a single `@AGENTS.md` line. Claude Code resolves it and shows it under project instructions in `/memory` as `@-imported`. That means the policy exists once, in the file `bmad-project-context` manages and audits, and `CLAUDE.md` adds only the operational layer: the trigger-phrase table, the completion-is-not-authorization statements, the three decline-the-push moments, the file-based state inventory, compaction preservation, and the scope test.

Do not duplicate policy across the two files. Two copies of a safety rule drift, and the working-rule protection means neither gets pruned automatically.

There is a third channel: Claude Code's auto-memory. Claude Code writes it itself, into `~/.claude/projects/<project>/memory/`, and loads it every session. It competes for the same context budget as the other two, grows without review, and lives outside the repository. Decide deliberately whether to review it at each epic close or turn it off.

## Thinking Mode Quick Reference

| Keyword(s) | Token Budget | When to Use |
|---|---|---|
| `think` | ~4,000 | Simple / mechanical tasks |
| `think hard` / `think deeply` / `think more` | ~10,000 | Light analysis |
| `ultrathink` / `think harder` | ~32,000 | Plan scrutiny, deep code review, complex debugging |
| `/effort low\|medium\|high\|max` | Adaptive | Persistent session setting |

Keyword triggers are per-prompt. `/effort` sustains depth. Alt+T toggles thinking. Ctrl+O shows it as gray italic text.

## Plan Mode in v6.5

Do **not** run build under Claude Code Plan Mode. Build writes its spec to disk during step-02; read-only mode breaks it.

Build's CHECKPOINT 1 replaces Plan Mode as the human gate, better positioned: it fires after investigation, with every Open Question answered by you, and freezes the approved intent afterward.

**The oneshot trap.** Step-02 routes to oneshot when "there are no intent gaps, nothing irreversible, and the change is small." On that route build writes a three-section spec, sets `status: in-progress`, and early-exits **without a checkpoint**. You never see a plan, and review drops from three layers to one.

This is pinned off at the project level. `_bmad/custom/bmad-build.toml` carries:

```toml
[workflow]
activation_steps_append = [
  "Never take the one-shot route on this project — always write the full spec and present CHECKPOINT 1.",
]
```

That is an instruction the agent should follow, not a gate it cannot pass. **Repeat it in the Stage 2 invocation anyway.** Belt and braces costs one sentence, and the 79% ceiling above is the reason.

Remove the override once your project's patterns stabilize and routine changes start appearing. Put a comment in the file naming the epic it is scoped to, or it becomes permanent by default.

## What Stays Manual and Why

| Step | Why Manual |
|---|---|
| CHECKPOINT 1 approval (Stage 2) | The human gate. Everything inside `<frozen-after-approval>` locks afterward. |
| Open Questions answers (Stage 2) | Build is forbidden from inventing these: "Do not invent the answer." |
| Story selection (Stage 1) | sprint-planning's recommendation is mechanical priority ordering. |
| Multi-goal split decision (Stage 2) | Build detects and proposes; you decide what ships. |
| Findings triage (Stage 5) | Which Stage 4 findings ship is product judgment. |
| Smoke testing (Stages 6, 8) | Exploratory by design. Catches what tests cannot. |
| Independent review session start (Stage 4) | The isolation is the product. |
| Marker creation | Per-commit authorization. |

From the docs: "Human attention is by far the most expensive resource, and the productivity bottleneck in AI-backed software development." Every manual step above has to earn that price.

## Compaction Reference

Auto-compaction fires near 83.5% context usage and is lossy. State lives in files, so this risks within-session continuity only.

The Stage 2 / Stage 3 split halves the worst v6.0 risk.

**Two sizing standards:**

- Docs: "A typical session is one goal: about 500 lines of code added or changed (not counting tests) in a small handful of files."
- Skill source: a spec targets a single user-facing goal within **900 to 1600 tokens**. Neither is a gate; both are proposals with override.

Step-02 shows the token count and offers a split above 1600. **Take the split.**

| After | Action | Preserve (via CLAUDE.md) |
|---|---|---|
| CHECKPOINT 1 approved | close the session | nothing; the spec is on disk and frozen |
| Implementation complete, before review | `/compact` | modified files, deviations, deferred items |
| Stage 4 review complete | close session | nothing; triage log is in the spec |
| Stage 5 fixes complete | `/clear` | clean break before PR mechanics |

## Mid-Session State

`.claude/skills/scratchpad.md` is retained, narrowed to Stage 5. Build maintains its own on-disk state: spec frontmatter, triage log, change log, `deferred-work.md`.

`[CALIBRATE]` `_bmad/scripts/memlog.py` ships with BMAD 6.9.0 and later. Evaluate replacing `scratchpad.md` with it after five stories. Do not switch mid-story.

## Automation Surface

| Artifact | Location | Role |
|---|---|---|
| `scripts/story-start.sh` | repo root | Stage 0: branch, preconditions, terminals |
| `scripts/story-cleanup.sh` | repo root | Stage 9 cleanup |
| `scripts/git-hooks/` | repo root | **New.** Tracked copies of the git hooks, since `.git/hooks/` is not version controlled |
| `.vscode/tasks.json` | `.vscode/` | Spawns and names six terminals on folderOpen |
| `.git/hooks/pre-commit` | `.git/hooks/` | **Existing gitleaks hook, extended** with the marker check |
| `.git/hooks/post-commit` | `.git/hooks/` | **New.** Clears the marker after each commit |
| `.git/hooks/pre-push` | `.git/hooks/` | **Existing.** Refuses direct push to `main`. Aligned with Stage 8; no change needed. |
| `AGENTS.md` | repo root | Agent instructions. Maintained by `bmad-project-context`. |
| `CLAUDE.md` | repo root | Authorization boundary and compaction rules |
| `.claude/skills/plan-gate.md` | `.claude/skills/` | Checklist applied at CHECKPOINT 1. From v5's `story-validate.md`. |
| `.claude/skills/cr-findings.md` | `.claude/skills/` | Stage 4 findings format. Re-pointed at `spec-{slug}.md`. |
| `.claude/skills/scratchpad.md` | `.claude/skills/` | Stage 5 mid-session state |
| `_bmad/custom/bmad-build.toml` | `_bmad/custom/` | Committed. Blocks the one-shot route while patterns are forming. |

### Git hooks

**Check which hook path your repository uses before installing anything.** Git reads hooks from `.git/hooks/` unless `core.hooksPath` is set. Husky sets it to `.husky`, at which point `.git/hooks/` is ignored entirely. Run `git config core.hooksPath`: nothing returned means `.git/hooks/`, a path returned means install there instead. Installing into the wrong one produces hooks that never run, with no error and no warning. The commands below assume `.git/hooks/`; substitute if yours differs.

**Check for an existing `pre-commit` hook before writing one.** A repository may already carry one, untracked and easy to miss. If it is there, append to it rather than replacing it, and keep any secret scanner first so a leak is caught even on an authorized commit.

**With no existing hooks,** install the shipped pair. The `pre-commit` secret scan is guarded, so it works whether or not gitleaks is on your PATH:

```bash
cp scripts/git-hooks/pre-commit scripts/git-hooks/post-commit .git/hooks/
chmod +x .git/hooks/pre-commit .git/hooks/post-commit
```

**With an existing `pre-commit`,** append only the marker check:

```bash
cat >> .git/hooks/pre-commit <<'HOOK'

[ -f .claude/.stage-6-active ] || {
  echo "Refused: no .claude/.stage-6-active marker. Commit not authorized."
  exit 1
}
HOOK
```

`post-commit` is what makes one marker authorize exactly one commit:

```sh
#!/bin/sh
rm -f .claude/.stage-6-active
```

`.git/hooks/` is not version controlled and does not survive a clone. Keep copies in `scripts/git-hooks/` and bootstrap a new clone with `cp scripts/git-hooks/* .git/hooks/ && chmod +x .git/hooks/*`. If you edit a hook, copy it back.

**Once the marker check is live, every commit needs the ritual**, including scaffolding commits. That is why hooks go last in the setup sequence.

### Keep `AGENTS.md` lean

The docs name bloated instruction files as the first cause of slow, degraded review: "There are too many rules in `AGENTS.md` and the other instruction files the agent reads every run... Those files blow the context window, or the agent wastes the run figuring out how to avoid them without losing review quality."

Every rule there is paid for on every review layer of every story, and the measured baseline is +20% inference cost for no gain unless the content clears the "what earns a line" test above.

Build's triage routes any finding whose fix edits `CLAUDE.md` or `AGENTS.md` to **defer**, never patch. Agent-context files are yours alone.

## BMAD Customization Surface

Three layers per skill, highest wins:

```
Priority 1 (wins): _bmad/custom/<skill>.user.toml   personal, gitignored
Priority 2:        _bmad/custom/<skill>.toml        team, committed
Priority 3 (base): the skill's own customize.toml   shipped defaults, DO NOT EDIT
```

**Four merge rules, by value shape.** The resolver does not treat fields differently by name:

| Shape | Rule |
|---|---|
| Scalar | Override wins |
| Table | Deep merge, recursively |
| Array of tables where every item has `code`, or every item has `id` | Merge by that key: matching replaces in place, new appends |
| Any other array | Append: base, then team, then user |

**Two rules that bite:**

- **No removal.** An override cannot delete a base item. Disable a review layer by overriding its `id` with an empty `instruction`.
- **Never copy the whole `customize.toml`.** Omitted fields inherit from below. A full copy shadows future defaults.

If you author your own array of tables, use `id` on every item or `code` on every item. Mixing falls back to append.

**Activation order:**

1. Resolve the `[workflow]` block (base, team, user).
2. Run `activation_steps_prepend`.
3. Load `persistent_facts`.
4. Load config and resolve standard variables.
5. Greet the user.
6. Run `activation_steps_append`.

Body begins after step 6.

### Keys in `bmad-build`

| Key | Default | Notes |
|---|---|---|
| `activation_steps_prepend` | `[]` | Before config load and greeting |
| `activation_steps_append` | **overridden** | Carries the no-oneshot rule on this project |
| `persistent_facts` | `[]` | Literal sentences, `file:` paths or globs, or `skill:` references |
| `on_complete` | `""` | A string, or an array of instructions run in order |
| `open_spec` | `""` | **Already disabled.** Leave it. |
| `implementation_handoff` | subagent recipe | The whole execution recipe for step-03 |
| `[[workflow.review_layers]]` | blind-hunter, edge-case-hunter, verification-gap | Dispatch route. `{diff_file}`, `{claims_file}` substituted. |
| `[[workflow.oneshot_review_layers]]` | blind-hunter only | Oneshot route |

The shipped `implementation_handoff`:

```toml
implementation_handoff = """
Launch a subagent with no prior conversation context, with this prompt:

> Read {spec_file} fully and implement it — the spec is the sole source of truth. Load every file listed in its frontmatter `context:` before you start.
>
> When done, report what you changed, how you verified it, and anything left incomplete or risky.
"""
```

Already context-free. The lever is **routing**: replace "Launch a subagent" with a bash invocation of an external coding CLI and implementation runs on a different model.

### Keys in `bmad-code-review`

Four layers: blind-hunter, edge-case-hunter, verification-gap, and **acceptance-auditor**, gated `when = 'Only when {review_mode} = "full".'`

`review_mode` is `full` when a spec is resolved. **Always give it the spec.** From the docs: "Review quality depends on it — without intent, the reviewers can only judge the diff against itself."

**Placeholder names differ.** Build's layers receive `{claims_file}`; code-review's acceptance-auditor receives `{spec_file}`. Both receive `{diff_file}`.

### Verify what resolved

```bash
uv run _bmad/scripts/resolve_customization.py \
  --skill "$(pwd)/.claude/skills/bmad-build" \
  --project-root "$(pwd)" \
  --key workflow
```

Omit `--key` for a full dump. Do this once per override before trusting it.

## VS Code Setup

One VS Code window per story. `story-start.sh` refuses to run while VS Code is open.

**Six terminals per story:**

| Terminal | Stage | Stage Title |
|---|---|---|
| `plan` | 2 | Plan |
| `spec-review` | 2b | Spec Review |
| `implement` | 3 | Implement |
| `review` | 4 | Independent Review |
| `fix` | 5 + 7 | Fix Issues, and Commit if needed |
| `ops` | 1, 6, 8, 9 | Sprint status, walkthrough, PR mechanics, cleanup |

The `review` terminal as a separate named panel is the structural enforcement of Stage 4 isolation.

Run every stage inside the VS Code terminal panel, not a standalone Terminal.app window. Build, code review, and walkthrough all emit `path:line` references designed to be clickable.

Slug derivation: `git branch --show-current | sed 's|^story/||'`.

# Part 2 - Full Story Cycle Workflow

## Stage 0 - Setup

| Attribute | Value |
|---|---|
| Model | n/a (script only) |
| Automation | `scripts/story-start.sh <story-number> <slug>` |

**Preconditions enforced by the script:**

- VS Code must NOT be running (Cmd+Q first).
- No stale marker at `.claude/.stage-6-active`.
- Working tree clean.
- Current branch is `main`.
- Target branch `story/<n-n>-<slug>` does not exist locally.
- `uv --version` succeeds.

**Actions:** `git pull --ff-only`, `git checkout -b story/<n-n>-<slug>`, `code <repo-root>`, six terminals spawn.

Build's step-01 runs its own VCS check and HALTs if the tree is dirty or the branch is a mismatch. `story-start.sh` guarantees both, so that gate should never fire.

## Stage 1 - Select and Gate

| Attribute | Value |
|---|---|
| Model | Sonnet |
| Window | `ops` |
| Thinking | Plain |
| Exit Condition | Next story key chosen and confirmed |

```
/model sonnet
show sprint status
```

Reports counts by status, risk flags, open retrospective action items, and one recommended next action with its story key. The recommendation is mechanical priority ordering. Override freely.

"validate sprint status" checks format without changing anything. "fix sprint status" rebuilds from epic files, story files, and git history, showing a proposed state table and writing nothing until you confirm. It is the only path allowed to mark a story less complete than it was.

If the epic needs re-scoping mid-sprint, that is `bmad-correct-course`.

Close the session. Run Stage 0 with the chosen key.

## Stage 2 - Plan

| Attribute | Value |
|---|---|
| Model | Opus |
| Window | `plan` |
| Thinking | `/effort max` |
| Plan Mode | **OFF.** Build writes the spec to disk. |
| Automation | `.claude/skills/plan-gate.md`, `_bmad/custom/bmad-build.toml` |
| Exit Condition | CHECKPOINT 1, choose **Approve and stop**. Spec is `ready-for-dev`. Close. |

```
/model opus
/effort max
also follow .claude/skills/plan-gate.md when build presents CHECKPOINT 1
```

```
/bmad-build implement story <story-key> from the sprint status file. Do not take the one-shot route — write the full spec and present CHECKPOINT 1.
```

**What happens:** epic context compiled or loaded from cache, previous-story continuity loaded, VCS check, multi-goal check, codebase investigation via subagents, route decision, spec written, token gate, Open Questions resolved, CHECKPOINT 1.

**Three things are yours:**

1. **The multi-goal split.** Build HALTs on two or more independently shippable deliverables. Split unless coupling risk is real. Deferred goals land in `deferred-work.md` with evidence.
2. **Open Questions.** Numbered, with options and consequences, then HALT. Build cannot invent answers. Yours are frozen as decisions. Expect a second round.
3. **The token gate.** Over 1600 tokens, take the split.

**At CHECKPOINT 1, choose "Approve and stop."**

- *Approve and continue* - proceeds to implementation in this session. The v6.0 behavior. Do not use it.
- *Approve and stop* - approves, sets `ready-for-dev`, stops. **Use this.**
- *Review spec* - reviews with a subagent. Useful, but Stage 2b does it better from a fresh session.

Build re-reads the spec from disk before acting on approval and acknowledges external edits, so editing it in your editor between presentation and approval is safe.

## Stage 2b - Spec Review

Optional but recommended. This is v5's Stage 1b.

| Attribute | Value |
|---|---|
| Model | Sonnet |
| Window | `spec-review` |
| Thinking | Plain |
| Exit Condition | Findings reviewed, spec edited if needed, session closed |

Baseline pass:

```
/model sonnet
follow .claude/skills/plan-gate.md to validate {implementation_artifacts}/spec-<slug>.md
```

For a spec with a real design tradeoff in it, use the Anti-Consensus Club instead:

```
/bmad-party-mode --party anti-consensus-club --mode subagent
```

| Member | Lens |
|---|---|
| Wildcard | Option generator: alternative problem statements, assumptions, examples |
| Level | Claim checker: support, missing information, confidence |
| Killjoy | Loop stopper: repetition, fake disagreement, unsupported speculation |
| Splinter | Consensus challenger: easy agreement, ignored tradeoffs |

**`--mode subagent` is not optional here.** Party mode's default `session` mode has one model voicing every persona, and the docs are blunt that this "tends to make them agree." `subagent` spawns a separate agent per persona every substantive round. Without it, Stage 2b is theater.

`bmad-advanced-elicitation` is the lighter alternative when one section needs sharpening rather than the whole spec needing challenge.

**Do not use the Code Review Crew here or at Stage 4.** It ships inactive, and the docs are explicit: it "argues. It does not verify or triage." It is a debate, not a review.

**Constraint:** `<frozen-after-approval>` is locked. Only you may edit it, and edits there mean a decision you recorded was wrong. Everything outside it is fair game.

## Stage 3 - Implement

| Attribute | Value |
|---|---|
| Model | Opus |
| Window | `implement` |
| Thinking | `/effort max` |
| Plan Mode | OFF |
| Compaction | **HIGH risk.** Longest session. |
| Exit Condition | Build commits locally and presents. STOP. Decline the PR offer. |

```bash
touch .claude/.stage-6-active
```

```
/model opus
/effort max
```

```
/bmad-build resume {implementation_artifacts}/spec-<slug>.md
```

Build reads `status: ready-for-dev` and early-exits straight to step-03. It does not re-plan.

**What happens:** `baseline_commit` captured, status `in-progress`, sprint status synced, implementation dispatched to a context-free subagent whose sole source of truth is the spec, unified diff staged, every task verified against the diff rather than the subagent's report, matrix test audit if applicable, three review layers in parallel, triage, loopbacks, then commit and present.

**Loopbacks**, processed in cascading order:

- `intent_gap` - root cause inside the frozen block. Build reverts and returns to you.
- `bad_spec` - root cause outside the frozen block. Build reverts, amends, logs, re-derives.
- `patch` - trivial fix. Re-engages the implementation subagent.
- `defer` - not this story's problem. Appended to `deferred-work.md`.

`review_loop_iteration` increments per loopback and halts above 5. Three loopbacks means the spec was weak; note it for the retro.

**At the end** build offers a PR, a walkthrough, or another change. **Decline the PR.**

**Read `deferred-work.md` after every run.**

## Stage 4 - Independent Review

| Attribute | Value |
|---|---|
| Model | Sonnet |
| Window | `review`. **Never `implement`.** |
| Thinking | `think harder` |
| Plan Mode | OFF |
| Automation | `.claude/skills/cr-findings.md` |
| Exit Condition | Findings written, issue IDs noted, session closed. **The story reaches `done` here or in the repeat pass — nowhere else.** |

```
/model sonnet
/bmad-code-review think harder
```

**Give it the spec.** Supplying `{implementation_artifacts}/spec-<slug>.md` sets `review_mode = full`, enabling the Acceptance Auditor layer and the `decision_needed` triage route.

```
follow .claude/skills/cr-findings.md when writing the Code Review Findings section to {implementation_artifacts}/spec-<slug>.md
```

**Triage routes differ from build's.** Code review uses patch, defer, and **decision_needed** (available only in `full` mode). Build uses intent_gap, bad_spec, patch, defer. A `decision_needed` finding is the highest-value output of this stage.

### Why Stage 4 is mandatory in v6.5

1. **It runs a layer build does not have.** Acceptance Auditor checks the diff against acceptance criteria, spec intent, missing specified behavior, and contradictions between spec constraints and code.
2. **Different model.** Build forces review subagents to the orchestrator's model capability.
3. **Different triage.** Build's triage is performed by the session that wrote the spec, and is told to reject any finding whose fix is to edit that spec.

### This stage is what sets `done`

`bmad-code-review` step-04 sets `new_status = done` only when every `decision-needed` and `patch` finding is resolved, and no unresolved `high` or `medium` remains. Nothing in Stages 5 through 9 syncs story status. Build set it to `review` at step-05 and that is where it stays until a clean code-review pass moves it.

**So a story whose Stage 4 found real issues does not reach `done` on the first pass.** Fix them at Stage 5, then run a short repeat pass here to verify and close.

Three things break if a story is left at `review`:

- The next story's Stage 2 loads continuity from the most recent **`done`** spec in the epic. A stuck story contributes nothing.
- `bmad-retrospective` rejects an epic with unfinished stories, so the epic cannot close.
- Stage 1's status view prioritizes "review what is waiting" and keeps recommending a story you consider finished.

Confirm after every story:

```bash
grep "<story-slug>" _bmad-output/implementation-artifacts/sprint-status.yaml
```

### Repeat passes, and when to stop

Hand a finished spec back to `bmad-build` and it skips straight to review and triage, repeatable. Mechanically, build routes `in-review` to step-04; a spec marked `done` is ingested as context rather than resumed, so either set `status: in-review` before re-invoking or simply run `bmad-code-review` again in a new `review` session. Prefer the latter; it keeps the model boundary.

**The stopping rule:**

> Stop when the findings are mostly low-value notes about exotic corner cases. That is accidental complexity, not quality. Non-trivial findings on a third pass of agentic review usually mean something is wrong upstream of this change: a weak spec, a contradiction, or ambiguity in the rules. Fix that instead of running another pass.

Adopt verbatim. A third pass producing real findings is a signal to fix the spec, `AGENTS.md`, or the epic.

## Stage 5 - Fix Issues

| Attribute | Value |
|---|---|
| Model | Opus |
| Window | `fix` |
| Thinking | `think`; escalate only for architectural ambiguity |
| Compaction | Medium. Split above six findings: H+M first, L second. |
| Exit Condition | Findings resolved, Status fields updated, **story confirmed `done`** via a repeat Stage 4 pass, terminal kept open for Stage 7 |

```
/model opus
also follow .claude/skills/scratchpad.md to maintain mid-session state at .claude/scratchpad.md
review the Code Review Findings section in {implementation_artifacts}/spec-<slug>.md and resolve all findings
```

Defer specific findings by ID: `resolve findings H1, M1, L2`. Update each Status to `resolved` or `deferred`, with a `Deferral note:` line when deferred.

**Scope is narrower than v5.** Build already fixed what belonged to its own change. If Stage 5 is routinely empty, record it; that is the experiment answering itself.

## Stage 6 - Walkthrough and Smoke

| Attribute | Value |
|---|---|
| Model | Sonnet |
| Window | `ops` |
| Thinking | Plain |
| Exit Condition | You have seen the change and believe it should ship |

```
/model sonnet
/bmad-walkthrough
```

**Human review**, explicitly not agentic review. No linters, no type checkers, no tests, no severities. A reading guide.

1. **Orientation** - identifies the change, one-line intent summary, surface-area stats: files changed, modules touched, lines of logic, boundary crossings, new public interfaces.
2. **Walkthrough** - organized by *concern*, not by file. Each concern gets why this approach, then clickable `path:line` stops. Sequenced top-down. Design judgment, not correctness.
3. **Detail Pass** - 2 to 5 spots where a mistake breaks the most, tagged by risk category (`[auth]`, `[schema]`, `[billing]`, `[public API]`, `[security]`) and ordered by blast radius. Earlier agentic findings surface here, specifically the decisions flagged rather than bugs already fixed.
4. **Testing** - 2 to 5 manual observations. Says so if the change has no user-visible behavior.
5. **Wrap-Up** - approve, rework, or discuss.

**At step 5, decline the push and PR offer.**

**It is a conversation.** Mid-walkthrough you can say "run advanced elicitation on the error handling" or "party mode on whether this migration is safe." Use those freely. If you want a code review, use the `review` terminal, or you have collapsed Stage 4 into Stage 6.

Then smoke test manually, guided by step 4. **Human gate; no agent role.**

Optional, for user-facing surface:

```
/bmad-qa-generate-e2e-tests Create API and E2E tests for <feature>.
```

Detects the existing framework, generates API tests where there are endpoints and E2E tests where there is UI, **runs them once and fixes failures**, writes `tests/test-summary.md` listing what is still uncovered. Ceiling is happy path plus one or two error cases. Generates tests only; will not second-guess Stage 4.

`[CALIBRATE]` Decide after three stories: every cycle, or only user-facing stories.

## Stage 7 - Commit

In the common path **there is nothing to do here.** Build committed at Stage 3 under your marker.

If Stage 5 changed files:

```bash
touch .claude/.stage-6-active
```

1. Ask Claude to recommend a commit message from the diff.
2. `git add <files>`, including `spec-<slug>.md`.
3. `git commit -m "fix: <message>"`. The post-commit hook clears the marker.

Prefer a separate `fix:` commit over amending build's.

**Batching multiple stories:** cycle Stages 0 through 7 per story, leaving commits unpushed. Run Stage 8 once after the final story. **Only safe if each story actually reaches `done` before the next one's Stage 2**, since continuity loads from the most recent `done` spec. Do not batch Stories 1 and 2; the Stage 4 experiment needs them separable.

## Stage 8 - Push, PR, CI, Merge

The `pre-push` hook refuses direct pushes to `main`. Story branches are unaffected.

**Your manual actions:**

1. **Push.** `git push -u origin story/<n-n>-<slug>`. One push covers all batched commits.
2. **Open PR.** `gh pr create --title "feat: <description>" --body-file /tmp/pr-body.md`.
3. **Wait for CI.** `gh pr checks <number>`.
4. **Smoke test in preview.** Human gate.
5. **Squash and merge.** `gh pr merge <number> --squash --delete-branch`.

**Automatic on push and merge:** `[PROJECT]` preview deploy, preview environment, CI checks, production deploy, teardown. Fill in once your pipeline exists.

**If a pushed change breaks something:** `git revert HEAD`, then a fresh chat and `bmad-build` with a different approach. Do not patch forward in the session that created the break.

**Claude Code role:** none.

## Stage 9 - Cleanup and Epic Close

```bash
./scripts/story-cleanup.sh story/<n-n>-<slug>
```

`--dry-run` available. Idempotent. Switches to main and pulls, deletes the local branch (handling squash-merge via `gh pr list --head <branch> --state merged`), clears the stale marker, clears the scratchpad, `[PROJECT]` triggers production migration if applicable.

### Epic close

**Mandatory in this framework.** See "Session Architecture Principles, and Their Cost."

```
/bmad-retrospective -H <epic>
```

`-H <epic>` is the stable orchestrator-facing interface: skips confirmations, takes the epic from the invocation, never opens team discussion, renders the verdict on evidence alone, records assumptions into the document's Assumptions section. Use plain `/bmad-retrospective 3` for the interactive version.

**What it looks for:**

- **Aggregate defects** - architecture that drifted, the helper written twice, the file that grew a little in every session.
- **Diff-scope review** - hands the epic's full diff to `bmad-review`, weighting the seams between stories.
- **Spec reconciliation** - where built code diverged from the epic and PRD.
- **A behavior check** - exercises changed flows end to end. Passing tests do not substitute for running the system.
- **Follow-through** - whether the previous epic's action items were done.
- **An acceptance verdict.**

Every finding carries a source reference. A claim it cannot point at does not make the report.

**Three verdicts:** `accepted`, `accepted-with-open-items`, `rejected`. Unfinished stories force `rejected`; you can override, but a failing epic never closes as quietly accepted. The verdict gates starting the next epic.

**The skill proposes; you decide.** Nothing touches code or specs automatically.

Team discussion is opt-in, never runs headless, and seeds `bmad-party-mode` with the Phase 2 findings. Agents speak only to findings with sources.

### Also at epic close

**Run `bmad-project-context` in audit intent.** It asks whether each line still changes agent behavior and ends with the block smaller or equal, never larger.

**Constrained by the working-rule protection:** a policy or pitfall is removed only when what it is about is gone, deleted, or now enforced by a tool, or when you remove it. Absence of recent failures is never grounds, because a working rule erases the evidence that it is still needed. The same protection covers every instruction you wrote by hand. Audit proposes; it does not prune your rules on its own authority.

Also:

- Triage `deferred-work.md`. Every entry has `source_spec` and `evidence`. Nothing else in the workflow clears this file.
- Update project documentation affected by the epic.
- Manage Claude projects: add docs, update changed docs, clean up chats.
- If the guide's version changed during this epic, publish the updated copy wherever it is shared and re-check that the README's Status section is still true.

---

# Part 3 - Reference and Summary

## Complete Flow Summary

| Stage | Model | Thinking | Terminal | Session Action | Automation |
|---|---|---|---|---|---|
| 0 Setup | n/a | n/a | any shell | Script + new VS Code window | `story-start.sh` |
| 1 Select and Gate | Sonnet | plain | `ops` | New, close after | `bmad-sprint-planning` status view |
| 2 Plan | Opus | `/effort max` | `plan` | New, **Approve and stop**, close | `bmad-build` steps 01-02 + `plan-gate` skill |
| 2b Spec Review | Sonnet | plain | `spec-review` | New, close after | `plan-gate` skill; Anti-Consensus Club in `subagent` mode |
| 3 Implement | Opus | `/effort max` | `implement` | New, marker first, STOP after commit | `bmad-build` steps 03-05 |
| 4 Independent Review | Sonnet | `think harder` | `review` | New, close after | `bmad-code-review` + `cr-findings` skill |
| 5 Fix Issues | Opus | `think` | `fix` | New, keep open for Stage 7 | `scratchpad` skill |
| 6 Walkthrough and Smoke | Sonnet | plain | `ops` | New, close after | `bmad-walkthrough`, optional `bmad-qa-generate-e2e-tests` |
| 7 Commit (fixes only) | Opus | plain | reuse `fix` | Marker + hook | `.git/hooks/pre-commit` |
| 8 Push through Merge | n/a | n/a | `ops` | Manual + CI/CD | `gh`, CI, `.git/hooks/pre-push` |
| 9 Cleanup and Epic Close | Sonnet for retro | plain | `ops` | Script, retro at epic close | `story-cleanup.sh`, `bmad-retrospective -H` |

## Build's Internal Triage, and Why Stage 4 Exists

Build's triage discards the reviewers' own severity grades ("they lack the context to grade"), verifies each claim at the cited location by reading past the diff hunk, and renders one of five verdicts: high, medium, low, `false` (with a refutation), or `maybe-false` (with what would settle it). Every finding gets a row in `## Review Triage Log`; none is dropped, merged, or silently skipped. Groups form only on shared root cause.

Anti-noise rules: reject `low` findings unlikely to be met in everyday use whose fix adds complexity; reject findings on their refutation; and a scope rule strict against itself, since a finding excluded only by the spec's scope section routes to `intent_gap` or `bad_spec` rather than being dropped.

**What Stage 4 adds:** the Acceptance Auditor question, the `decision_needed` route, a triage pass with no authorship attachment, and a different model.

**What Stage 4 does not add:** raw finding volume. One real acceptance violation on a foundational story pays for the practice.

## Compaction Risk by Stage

| Stage | Risk | Handling |
|---|---|---|
| 1 Select | Low | none |
| 2 Plan | Medium | Take the 1600-token split |
| 2b Spec Review | Low | none |
| 3 Implement | **High** | `/compact` before review; keep the spec under 1600 tokens |
| 4 Independent Review | Medium | Large diffs compress; Sonnet helps |
| 5 Fix Issues | Medium | Split above six findings |
| 6 Walkthrough | Low | none |
| 7 Commit | Low | none |

## Git Branch Workflow

| Step | Command |
|---|---|
| Start from up-to-date main | `git checkout main && git pull --ff-only` |
| Create feature branch | `git checkout -b story/<n-n>-<slug>` |
| Authorize build's commit | `touch .claude/.stage-6-active` (Stage 3 entry) |
| Build commits | (build does this at step-05) |
| Authorize a fix commit | `touch .claude/.stage-6-active` |
| Commit fixes | `git add <files> && git commit -m "fix: description"` |
| Push branch | `git push -u origin story/<n-n>-<slug>` |
| Open PR | `gh pr create --title "feat: description" --body-file /tmp/pr-body.md` |
| Merge | `gh pr merge <num> --squash --delete-branch` |
| Undo a bad pushed commit | `git revert HEAD` |
| Clean up | `./scripts/story-cleanup.sh story/<n-n>-<slug>` |

Direct pushes to `main` are refused by the pre-push hook. That is correct and aligned with Stage 8.

## Quick Decision Rules

| Situation | Action |
|---|---|
| Starting a new story | Cmd+Q VS Code, then `./scripts/story-start.sh <n-n> <slug>` |
| Don't know which story is next | Stage 1, `show sprint status`, then your own judgment |
| Epic needs re-scoping mid-sprint | `bmad-correct-course` |
| Starting Plan | Never under Claude Code Plan Mode |
| Build detects multiple goals | Split unless coupling risk is real |
| Build asks Open Questions | Answer carefully; these get frozen. It cannot invent them. |
| Spec exceeds 1600 tokens | Take the split |
| Build proposes the oneshot route | Refuse. The override should prevent it; say it in the prompt too. |
| At CHECKPOINT 1 | **Approve and stop.** Never Approve and continue. |
| Spec has a real design tradeoff | Stage 2b with `--party anti-consensus-club --mode subagent` |
| Party mode running in default `session` mode | Switch to `subagent`. Default mode manufactures agreement. |
| Starting Implement | `touch .claude/.stage-6-active` first |
| Build, walkthrough, or review offers to push or open a PR | Decline. Stage 8 owns that. |
| Starting Independent Review | Use the `review` terminal. Give it the spec so `review_mode = full`. |
| A `decision_needed` finding appears | Highest-value output of Stage 4. Answer it yourself. |
| Stage 5 changed files | Repeat pass in the `review` terminal. That is what sets `done`. |
| Story still shows `review` after Stage 5 | It is not closed. Repeat pass, or the epic cannot close. |
| Third review pass still finding real issues | Stop reviewing. Fix the spec, `AGENTS.md`, or the epic. |
| `review_loop_iteration` reached 3+ | The spec was weak. Note it for the retro. |
| Review suddenly takes an hour or gets stupid | Resume that session and ask why. Usual causes: bloated `AGENTS.md`, huge files, platform subagent changes. |
| More than six findings at Stage 5 | Split: H+M in one session, L in another |
| Context warning mid-implement | `/compact`, preserving modified files and plan deviations |
| Session complete | Kill it |
| Multiple stories in one epic | Cycle Stages 0-7 per story; Stage 8 once at the end |
| Pushed change broke something | `git revert HEAD`, fresh chat, different approach |
| Story merged | `./scripts/story-cleanup.sh story/<n-n>-<slug>` |
| Epic closed | Retro is mandatory here, then `bmad-project-context` audit, then triage `deferred-work.md` |
| Retro verdict is `rejected` | Do not start the next epic. Fix first, or override consciously. |
| Tempted to add a rule to `AGENTS.md` | Apply the "would removing this line change agent behavior" test first |
| Tempted to remove a rule from `AGENTS.md` | Only if the thing it is about is gone or tool-enforced. No recent failures is not evidence. |
| A skill halts on missing config | Add the key. 6.11+ halts rather than rendering empty. |
| `bmad-build` refuses to start | Check `uv --version`. The installer only warned; build halts. |
| An override seems not to apply | `resolve_customization.py --key workflow`. Check placement and filename. |
| An update broke an override | You copied the whole `customize.toml`. Trim to only changed fields. |
| Hooks do not seem to fire | Check `git config core.hooksPath`. A path such as `.husky` means `.git/hooks/` is ignored entirely. |

## Tips and Troubleshooting

**PR body construction.** zsh interprets backticks and `${...}` inside double quotes. Use a quoted heredoc:

```bash
cat > /tmp/pr-body.md <<'PRBODY'
## Summary
Description here. Backticks `like this` and ${variable} expressions are safe
because the heredoc terminator is quoted ('PRBODY').

## Verification
- Item one
- Item two
PRBODY

gh pr create --title "..." --body-file /tmp/pr-body.md
```

**TOML authoring gotchas:** strings quoted, `[section]` for tables, `[[section]]` for arrays of tables, and **a table's scalar or array keys must come before any of its `[[subtables]]`**. That last one silently reparents keys. For workflows, fields belong under `[workflow]`.

**Reset an override.** Delete the file from `_bmad/custom/`.

**Verify the catalog, not the changelog.** `bmad-help` per machine.

**Do not install shims.** A fresh 6.12.0 install without `--shims` gets none, and keeping them off avoids the v7 removal deadline.

**Do not port this to a project mid-release.** A shipping project on an older BMAD version should stay there until it has room for toolchain churn. Hook setup in particular is not interchangeable between projects: one may use husky, another the default `.git/hooks/` path.

## Generating a Shareable Version

Canonical version is the Markdown file at `docs/story-cycle-guide-v6.5.md`. Everything else is generated from it.

The pipeline is `scripts/build-workflow-doc.sh`. It converts a workflow markdown doc to Google-Docs-friendly HTML using pandoc with two project helpers: `docs/_pandoc/header.html` for table CSS, and `docs/_pandoc/remove-hr.lua` to strip horizontal rules that import badly.

```bash
./scripts/build-workflow-doc.sh docs/story-cycle-guide-v6.5.md
```

Output lands beside the input with a `.html` extension. Then:

1. Upload the `.html` to Google Drive.
2. Right-click, Open with, Google Docs.
3. Cursor to the top, Insert, Table of contents, "With blue links."

Pandoc's `--toc` is deliberately omitted; its anchor links break on Google Docs import, and the native table of contents works correctly.

**Requires `brew install pandoc`** on this machine. The generated `.html` is derived from a tracked source and should be gitignored rather than committed.

For a Word file, pandoc converts directly, though this is not the established path:

```bash
pandoc docs/story-cycle-guide-v6.5.md -o /tmp/story-cycle-guide-v6.5.docx
```

## v7 Future Direction (Not in v6.5)

- **Worktree-per-story.** Motivated by `bmad-build-auto` and `bmad-loop`, which assume a clean tree between iterations.
- **Unattended runs on the stable tail of an epic.** From the docs: "Use `bmad-build` for foundational, risky, or important stories where your decisions may set patterns for later work. Once those patterns are stable, `bmad-build-auto` can run one unit without waiting for you." Build Auto adds a fourth review layer, computes `followup_review_recommended`, and writes a terminal status (`done`, `ready-for-dev`, `blocked`) an orchestrator can act on. Already installed here.
- **`stories.yaml` as the tracking file** for spec-backed work. Retrospective supports the same shape as "stories mode," writing `RETROSPECTIVE.md` in the spec folder.
- **`on_complete` hooks** firing `story-cleanup.sh`. It accepts an array of instructions run in order.
- **memlog replacing scratchpad.** `_bmad/scripts/memlog.py` is installed.
- **TEA module** if generated coverage needs fixtures and more test levels.
- **A planning-context capability.** BMAD has said this is coming separately. When it lands, this guide may have a home other than `docs/workflow/`.
- **Long-lived `epic/N-slug` branches** as integration target. Carried from v5, still unimplemented.
- **`uv` everywhere.** v7 standardizes every Python-running skill on `uv run`.

Defer all of this until v6.5 has run a full epic.

---

End of v6.5.
