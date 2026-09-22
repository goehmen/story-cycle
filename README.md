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

## Adopting it

1. Install BMAD in your project and confirm `uv run python -V` reports 3.11 or later.
2. Copy `scripts/`, `.vscode/tasks.json`, and `.claude/skills/` into your repository.
3. Install the hooks: `cp scripts/git-hooks/* .git/hooks/ && chmod +x .git/hooks/*`. If your repo already has a pre-commit hook, append the marker check to it rather than replacing it, and keep any secret scanner first.
4. Write your `AGENTS.md` and `CLAUDE.md`. The guide's "Agent Instruction Files" section covers what earns a line in those files and what actively hurts.
5. Fill in the project-specific section at the bottom of `.claude/skills/plan-gate.md` with checks particular to your stack.
6. Read the guide.

Decide early what your repository tracks. BMAD's installed trees are regenerable and produce noisy diffs on every update, so they are usually better ignored. Your planning artifacts directory is not optional: `bmad-build` commits the spec as part of its run, so an untracked artifacts directory gets swept into a story commit.

## Status

**This method has not yet been validated by running a full epic with it.**

It was derived from the BMAD 6.12.0 tagged source, its documentation, published research on agent instruction files, and prior experience with an earlier version of this workflow on BMAD 6.0.8. Every claim in the guide comes from one of those, not from use.

Treat it as a starting point to adapt rather than a proven recipe. If you run it and something is wrong, that is better evidence than anything currently in the document.

## Relationship to BMAD

Story Cycle is not affiliated with or endorsed by BMAD Code, LLC. It is a wrapper that calls BMAD's skills and depends on a BMAD installation. BMAD is MIT licensed and has its own trademark policy; see the [BMAD Method repository](https://github.com/bmad-code-org/BMAD-METHOD).

No BMAD source is vendored here. The guide quotes short passages from BMAD's own documentation where it matters for understanding behavior.

## License

MIT. See [LICENSE](LICENSE).
