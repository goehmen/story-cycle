# Story Cycle

A wrapper around [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD) that adds session isolation, model diversity, and an explicit authorization boundary to AI-assisted development in [Claude Code](https://claude.com/claude-code).

Built for solo work, where there is no second developer to catch what the first one missed.

## What problem it solves

BMAD 6.12's `bmad-build` does a lot in one run. It investigates the codebase, writes a spec, implements it, reviews its own work with three parallel reviewers, fixes what belongs to the change, and commits. That loop is good, and for many changes it is enough.

It also means the session that wrote the spec is the session that judges the review findings against it, under an explicit instruction to reject any finding whose fix would edit that spec. And it means one long session holds investigation, planning, implementation, and review in a single context window.

Story Cycle splits that run across separate sessions, each killed when its stage ends, with state carried in files rather than conversation history. A reviewer never shares context with the thing it is reviewing.

## What it adds

- **Ten stages, six named terminals.** One VS Code window per story. The terminals are pre-spawned and named after the stages, so the isolation is structural rather than remembered.
- **A commit authorization gate.** `git commit` is refused unless a marker file exists, which only a human creates. One marker authorizes exactly one commit, then a post-commit hook clears it. Agents have no path to advance the workflow on their own.
- **Model diversity across the review boundary.** Planning and implementation run on the stronger model; validation and review run on a different one.
- **A plan gate.** A fixed checklist applied to the spec before implementation starts, from a session that did not write it.
- **Two things BMAD marks optional, made mandatory.** A standalone `bmad-code-review` pass, because it runs an Acceptance Auditor layer and a `decision_needed` triage route that `bmad-build` does not have. And the epic retrospective, because maximum isolation maximizes the defect class isolation hides: architecture drift, the helper written twice, the file every session grew slightly.

## The cycle

| Stage | Terminal | What happens |
|---|---|---|
| 1 Select and Gate | ops | Read sprint status, choose the next story |
| 0 Setup | any shell | `story-start.sh` branches and spawns the terminals |
| 2 Plan | plan | `bmad-build` investigates and writes the spec, then stops at its checkpoint |
| 2b Spec Review | spec-review | Validate the spec from a fresh session |
| 3 Implement | implement | Marker first, then `bmad-build` resumes and implements, reviews, commits |
| 4 Independent Review | review | `bmad-code-review` with the spec supplied |
| 5 Fix Issues | fix | Resolve findings, then repeat Stage 4 to close the story |
| 6 Walkthrough and Smoke | ops | Guided human review, then manual smoke test |
| 7 Commit | fix | Usually nothing; the build already committed |
| 8 Push, PR, Merge | ops | Manual, no agent role |
| 9 Cleanup | ops | `story-cleanup.sh`, plus the retrospective at epic close |

The full reference is [`docs/story-cycle-guide-v6.5.md`](docs/story-cycle-guide-v6.5.md). Start with its "The Cycle at a Glance" section, which walks one story end to end in two pages. The rest is reference.

## What is in this repo

| Path | Purpose |
|---|---|
| `docs/story-cycle-guide-v6.5.md` | The method, in full |
| `scripts/story-start.sh` | Stage 0: preconditions, branch, launch |
| `scripts/story-cleanup.sh` | Stage 9: branch delete, marker and scratchpad clear |
| `scripts/build-workflow-doc.sh` | Markdown to Google-Docs-friendly HTML via pandoc |
| `scripts/git-hooks/` | Commit gate, marker clear, and a guard against direct pushes to `main` |
| `.vscode/tasks.json` | Spawns the six named terminals on folder open, each with its stage commands in scrollback |
| `.claude/skills/plan-gate.md` | The spec validation checklist |
| `.claude/skills/cr-findings.md` | Findings format for the independent review |
| `.claude/skills/scratchpad.md` | Mid-session state externalization |

## Requirements

- BMAD Method 6.12.0 or later, installed in your project
- Claude Code
- `uv` with Python 3.11 or later. BMAD's rendered skills halt without it, and the BMAD installer only warns rather than blocking, so an install can look healthy and fail at first build.
- Node 20.12 or later, `git`, `gh`, VS Code with the `code` CLI
- pandoc, only if you want the document build script

## Version compatibility

Story Cycle versions are bound to BMAD releases, because BMAD's Phase 4 skills changed shape significantly between them.

| Story Cycle | BMAD Method | Notes |
|---|---|---|
| v6.5 (this repo) | 6.12.0 | Phase 4 is `bmad-sprint-planning` then `bmad-build` then `bmad-code-review` |
| v5 | 6.0.8 | Predates the Phase 4 collapse. Used `bmad-create-story` and `bmad-dev-story`, deprecated in 6.11.0 and opt-in from 6.12.0. Not published here. |

On a BMAD release older than 6.11.0, this guide will not match your installed skills.

## Installing into your project

From your project root, with BMAD already installed:

```bash
git clone https://github.com/goehmen/story-cycle.git /tmp/story-cycle

mkdir -p scripts/git-hooks .vscode .claude/skills
cp /tmp/story-cycle/scripts/*.sh scripts/
cp /tmp/story-cycle/scripts/git-hooks/* scripts/git-hooks/
cp /tmp/story-cycle/.vscode/tasks.json .vscode/
cp /tmp/story-cycle/.claude/skills/*.md .claude/skills/
chmod +x scripts/*.sh scripts/git-hooks/*
```

Install the hooks:

```bash
cp scripts/git-hooks/* .git/hooks/ && chmod +x .git/hooks/*
```

If your repository already has a `pre-commit` hook, do not overwrite it. Append the marker check to the existing file instead, and keep any secret scanner first so a leak is caught even on an authorized commit:

```bash
cat >> .git/hooks/pre-commit <<'HOOK'

[ -f .claude/.stage-6-active ] || {
  echo "Refused: no .claude/.stage-6-active marker. Commit not authorized."
  exit 1
}
HOOK
```

Add to your `.gitignore`:

```
.claude/.stage-6-active
.claude/scratchpad.md
```

The marker especially. If it is ever committed it exists in every clone, the commit gate passes unconditionally forever, and the authorization boundary is silently defeated.

Then:

1. Turn on VS Code automatic tasks, once per machine. Command Palette, "Preferences: Open User Settings (JSON)", add `"task.allowAutomaticTasks": "on"`. Without this the six terminals will not spawn and nothing will tell you why.
2. Write your `AGENTS.md` and `CLAUDE.md`. The guide's "Agent Instruction Files" section covers what earns a line in those files and what actively hurts. `bmad-project-context` will produce a first draft of `AGENTS.md`.
3. Fill in the project-specific section at the bottom of `.claude/skills/plan-gate.md` with checks particular to your stack.
4. Decide what git tracks. BMAD's installed trees are regenerable and produce noisy diffs on every update, so they are usually better ignored. Your planning artifacts directory is not optional: `bmad-build` commits the spec as part of its run, so an untracked artifacts directory gets swept into a story commit.

## Your first story

Assuming BMAD planning is complete and you have epics plus a sprint status file. Substitute your own story number and slug throughout.

**Stage 1, pick the story.** Any shell, on `main`:

```
claude
/model sonnet
show sprint status
```

It recommends a next story by mechanical priority ordering. You decide whether that is the right next thing. Close the session.

**Stage 0, set up.** Quit VS Code first, then:

```bash
./scripts/story-start.sh 1-1 your-story-slug
```

A fresh VS Code window opens with six named terminals. On a repository VS Code has never opened, a trust prompt appears over the terminal panel and can make it look like nothing spawned. Grant trust and they are there.

**Stage 2, plan.** In the `plan` terminal:

```
claude
/model opus
/effort max
also follow .claude/skills/plan-gate.md when build presents CHECKPOINT 1
/bmad-build implement story 1-1 from the sprint status file. Do not take the one-shot route. Write the full spec and present CHECKPOINT 1.
```

Three things are yours here. If build detects two independently shippable goals it halts and offers to split; take the split. It then presents Open Questions and halts; it is forbidden from inventing those answers, and yours get frozen into the spec. If the spec exceeds 1600 tokens it offers a scope split; take that too.

At CHECKPOINT 1, choose **Approve and stop**, never "Approve and continue." Close the session.

**Stage 2b, validate the spec.** In the `spec-review` terminal:

```
claude
/model sonnet
follow .claude/skills/plan-gate.md to validate _bmad-output/implementation-artifacts/spec-1-1-your-story-slug.md
```

Close the session.

**Stage 3, implement.** In the `implement` terminal, authorize the commit first:

```bash
touch .claude/.stage-6-active
```

```
claude
/model opus
/effort max
/bmad-build resume _bmad-output/implementation-artifacts/spec-1-1-your-story-slug.md
```

Build reads `status: ready-for-dev` and jumps straight to implementation. At the end it offers to open a PR. Decline. Read `deferred-work.md`. Close the session.

**Stage 4, independent review.** In the `review` terminal, never the `implement` one:

```
claude
/model sonnet
/bmad-code-review think harder
```

Supply the spec path when it asks. This matters: it sets `review_mode = full`, which is what enables the Acceptance Auditor layer and the `decision_needed` route. Then:

```
follow .claude/skills/cr-findings.md when writing the Code Review Findings section to _bmad-output/implementation-artifacts/spec-1-1-your-story-slug.md
```

**Stage 5, fix.** In the `fix` terminal:

```
claude
/model opus
also follow .claude/skills/scratchpad.md to maintain mid-session state at .claude/scratchpad.md
review the Code Review Findings section in _bmad-output/implementation-artifacts/spec-1-1-your-story-slug.md and resolve all findings
```

If anything changed, go back to the `review` terminal for a short repeat pass. That is what sets the story to `done`, and nothing else does.

**Stages 6 through 9** are in the guide. Walkthrough and manual smoke, then push, PR, merge, then `./scripts/story-cleanup.sh story/1-1-your-story-slug`.

### The five things that go wrong

1. Forgetting the marker before Stage 3. Build does all the work, then its commit is refused.
2. Choosing "Approve and continue" at CHECKPOINT 1. Collapses Stages 2 and 3 into one session and loses the isolation the design rests on.
3. Running code review in the `implement` terminal. Same failure, worse: the review inherits the build's framing.
4. Letting build take the one-shot route. One review layer instead of three, and no checkpoint at all.
5. Leaving a story at `review`. `bmad-code-review` sets `done` only on a clean pass, and nothing else in the cycle syncs status. This one is silent: nothing errors, the story just never closes, and the next story loses its continuity while the epic cannot close.

## Status

**This method has not yet been validated by running a full epic with it.**

It was derived from the BMAD 6.12.0 tagged source, its documentation, published research on agent instruction files, and prior experience with an earlier version of this workflow on BMAD 6.0.8. Every claim in the guide comes from one of those, not from use.

Treat it as a starting point to adapt rather than a proven recipe. If you run it and something is wrong, that is better evidence than anything currently in the document.

## Relationship to BMAD

Story Cycle is not affiliated with or endorsed by BMAD Code, LLC. It is a wrapper that calls BMAD's skills and depends on a BMAD installation. BMAD is MIT licensed and has its own trademark policy; see the [BMAD Method repository](https://github.com/bmad-code-org/BMAD-METHOD).

No BMAD source is vendored here. The guide quotes short passages from BMAD's own documentation where it matters for understanding behavior.

## License

MIT. See [LICENSE](LICENSE).
