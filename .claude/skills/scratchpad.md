# Scratchpad — Mid-Session State Externalization Skill

## When to use this skill

Stage 5 (Fix Issues) of the Story Cycle workflow. After each logical task chunk, write your current session state to `.claude/scratchpad.md` using the format below.

Invoke via the Stage 5 prompt: `also follow .claude/skills/scratchpad.md to maintain mid-session state at .claude/scratchpad.md`.

**Optional at Stage 3 (Implement).** `bmad-build` maintains its own on-disk state as it runs — spec frontmatter (`status`, `baseline_commit`, `review_loop_iteration`), the triage log, the spec change log, and `deferred-work.md` — so build's own artifacts are the primary recovery point there. Use the scratchpad at Stage 3 only when a build session is running unusually long and you want a second record. Do not let it duplicate what the spec already says.

## Why this exists

The scratchpad is your **external recovery point**.

Claude Code uses internal context compaction when conversation history grows large. Compaction is lossy — it summarizes earlier context rather than retaining it verbatim. Even with the preservation rules in `CLAUDE.md`, compaction risks losing detail.

The scratchpad solves a different problem: **lossless on-disk state**. If compaction fires mid-session, you re-read this file to know exactly where you were without depending on the compaction summary. The file also makes cross-session recovery possible, such as resuming the next morning from a fresh session.

`CLAUDE.md` instructs you to preserve state during compaction. This skill instructs you to also externalize that state. Belt and suspenders, intentionally.

## Lifecycle

- **One file per story.** Path: `.claude/scratchpad.md`. Single file, not per-stage.
- **Rewrite per stage.** If Stage 3 wrote to the scratchpad, Stage 5 overwrites it. Do not append across a stage boundary. Stage 5 is a different session with different concerns; carrying Stage 3's state forward adds noise.
- **Within a stage, prepend — don't overwrite.** A stage can run more than once: Stage 5 may split into an H+M pass and an L pass, a repeat review can send you back into it, and a red preview check after Stage 8 puts you back in fix mode against the same story. Overwriting on each round destroys the record of what the earlier rounds decided, which is exactly what a later reviewer needs. Put the newest round at the top with a dated one-line header and leave the earlier rounds below it. The rewrite rule above governs **stage boundaries only**.
- **Cleared at Stage 9 (Cleanup).** `scripts/story-cleanup.sh` empties the file post-merge, as step 3 of four. You do not clear it yourself.

Do not "correct" stage numbers found in older artifacts. v5 had eight stages; v6 has ten, and a v5-era file saying "Stage 4 (Fix)" means what v6 calls Stage 5.

## Required sections

Update these seven sections in place as work progresses. Always include all seven, even if a section is empty (write `(none yet)` rather than omitting).

```markdown
# Scratchpad

## Story
- **Slug:** <x-x-slug>
- **Stage:** 5 (Fix Issues) | 3 (Implement)
- **Started:** <ISO timestamp when scratchpad first written for this stage>

## Current task
<one or two sentences describing exactly what you are working on right now>

## Modified files
- path/to/file.ts
- path/to/another.ts
<running list; append as files are created or modified>

## Decisions
- <one-line decision> — <one-line rationale>
<running list; never delete entries, only append>

## Test status
- **Last run command:** <e.g. npm run test -- src/import>
- **Result:** <e.g. 14 pass, 1 fail>
- **Failures:** <named test files or "none">

## Branch
<git branch --show-current output>

## Uncommitted paths
<output of `git status --porcelain` at the most recent update>
```

Until Story 1.1 scaffolds the app, **Test status** has no real command to record. Write `(no test framework yet)` rather than inventing one.

## When to write

After each **logical task chunk**. A logical task chunk is a unit of work that, if interrupted, you would not want to redo. Examples:

- Resolving one finding from the Code Review Findings section.
- Modifying a function and its tests in tandem.
- Adding a database migration.
- Adding a new file with substantial content.

A logical task chunk is **not**:

- A single character edit.
- Reading a file.
- Running a single test command in passing.

Frequency target: every 5 to 15 minutes of focused work, or whenever you complete a task you would not want to redo from scratch.

## What to write — content guidance

**Current task:** Be specific. "Resolving H1 by routing the bulk import path through the shared validator, in src/import/bulk.ts:88." Not "fixing bugs."

**Modified files:** Append paths as you touch them. Never prune. If you create then delete a file in the same session, still leave it on the list with a `(deleted)` suffix.

**Decisions:** Capture any choice that was not obvious, with its rationale. Skip mechanical choices.

**Test status:** Snapshot of the last test run only. No history. Always include the command so resumption can re-run it.

**Branch and Uncommitted paths:** Snapshot to disk so resumption knows the git state without re-querying. Especially important if compaction loses earlier git observations.

## Recovery procedure

If you encounter a fresh session pointing at a partially complete scratchpad:

1. Read the entire scratchpad first.
2. Run `git branch --show-current` and `git status --porcelain` and compare against the scratchpad. A mismatch means either someone made changes since it was written, or it is stale from a prior story because `scripts/story-cleanup.sh` failed to clear it.
3. If mismatched, stop and ask the user before proceeding.
4. If consistent, resume the **Current task** with **Modified files** and **Decisions** as context. Re-run the **Last run command** to confirm test status has not drifted.

## What NOT to put in scratchpad

- Conversation history. Compaction handles that.
- Acceptance criteria or frozen intent. Read `spec-<slug>.md` directly.
- Code review findings. Read the spec file's `## Code Review Findings` section.
- Anything from build's `## Review Triage Log` or `deferred-work.md`. Those are already on disk.
- Long-form notes. The scratchpad is a state snapshot, not a journal.
- Anything you would not need on session restart.

## Relationship to CLAUDE.md compaction rules

`CLAUDE.md` names what to preserve through a deliberate compact:

- **Implement:** modified files, deviations from the spec, deferred items.
- **Fix Issues:** which findings are resolved, which are deferred and why.

The scratchpad's seven sections are the on-disk superset of those rules. Whatever `CLAUDE.md` instructs the agent to preserve internally during compaction, the scratchpad records externally for cross-session resumption. They are complementary safety nets for the same class of state loss.
