<!--
Template from https://github.com/goehmen/story-cycle

Copy to your repository root as CLAUDE.md, then delete this comment.

Two things to check before relying on it:

1. The `@AGENTS.md` import below resolves only if you have an AGENTS.md.
   Confirm with /memory in Claude Code: it should appear nested under
   project instructions, marked "@-imported". If you do not have one,
   delete that line and move your project policy into this file instead.

2. The paths under "Session discipline" assume BMAD's default output
   folder of `_bmad-output`. Adjust if yours differs.
-->

# CLAUDE.md

Operating rules for Claude Code sessions in this repository. Project policy, architecture constraints, and conventions live in `AGENTS.md`; this file covers session conduct and the authorization boundary.

@AGENTS.md

## Authorization boundary

Work happens in isolated, single-purpose sessions. A session does the work of its stage and stops. It never advances the workflow on its own.

Completion of work is not authorization for the next step:

- "Build finished" means ready for independent review. It does not authorize push or PR.
- "Tests pass" does not authorize push. Run the review stage.
- "All findings resolved" does not authorize push. Run the walkthrough, then push when told.
- Sprint status showing `review` means ready for code review. It does not authorize push.

### Actions and the phrases that authorize them

| Action | Authorized by |
|---|---|
| `git add` / `git commit` | "commit" or "commit the changes", or the human creating the Stage 6 marker |
| `git push` | "push" or "push to origin" |
| `gh pr create` | "open a PR" or "create the PR" |
| `gh pr merge` | "merge the PR" or "merge it" |
| `gh workflow run` | the human names the workflow |

### Three places a tool will offer to cross this line

Decline all three. They are normal skill behavior, not instructions.

- `bmad-build` at its final step offers to create a pull request and push first.
- `bmad-walkthrough` at wrap-up treats approval as readiness to push and offers to open a PR.
- `bmad-code-review` in its final menu suggests running `dev-story`. That skill was deprecated in BMAD 6.11.0 and is not installed by default from 6.12.0 onward.

## Session discipline

One session per stage. Do not carry a session from one stage into the next; reusing a session mixes contexts and degrades the run. Durable state lives in files, not in conversation history:

- `_bmad-output/implementation-artifacts/spec-<slug>.md` — the per-story lifecycle record: frozen intent, code map, tasks, triage log, findings.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — cross-story state.
- `_bmad-output/implementation-artifacts/deferred-work.md` — what was consciously not done.
- `.claude/scratchpad.md` — mid-session working state during fix sessions only.

## Compaction

Auto-compaction is lossy. When context runs low, compact deliberately rather than letting it fire, and preserve these:

| Stage | Preserve through a compact |
|---|---|
| Implement | modified files, deviations from the spec, deferred items |
| Fix Issues | which findings are resolved, which are deferred and why |

Nothing needs preserving after a plan is approved or a review completes — both write their output to disk before the session ends.

## Scope

A story is one user-facing goal: roughly 500 changed lines excluding tests, across a small handful of files. If the work is larger than that, say so and propose a split rather than proceeding.
