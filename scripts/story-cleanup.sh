#!/usr/bin/env bash
# story-cleanup.sh — Stage 9 cleanup automation for the Story Cycle workflow (v6.4).
#
# Performs the post-merge cleanup steps that remain manual in solo-founder dev:
#   1. Local branch delete (after confirming it merged to main, via fast-forward
#      OR via squash-merged PR)
#   2. Stale Stage 6 marker clear (defense in depth)
#   3. Scratchpad clear (empty .claude/scratchpad.md if it exists)
#   4. [PROJECT] Post-merge deploy/migration hook — wire up per project
#
# Out of scope (handled elsewhere):
#   - Vercel preview cleanup  → auto-handled by Vercel on PR close
#   - Epic retrospective      → /bmad-retrospective -H <epic>, run manually
#   - deferred-work.md triage → manual, at epic close
#
# Usage:
#   ./scripts/story-cleanup.sh <branch-name>            # run cleanup
#   ./scripts/story-cleanup.sh <branch-name> --dry-run  # show what would happen
#
# Exits non-zero on any failure. No interactive prompts.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRATCHPAD_PATH=".claude/scratchpad.md"

# [PROJECT] Set to the workflow filename once your project has a production
# migration or deploy workflow (e.g. "migrate-production.yml"). Leave empty to
# skip Step 4 entirely.
PROD_MIGRATION_WORKFLOW=""

usage() {
  cat <<USAGE
Usage: ${SCRIPT_NAME} <branch-name> [--dry-run]

Arguments:
  <branch-name>   The local branch to clean up. Must already be merged to main
                  (fast-forward OR squash via merged PR).

Options:
  --dry-run       Print actions without executing them.
  -h, --help      Show this help.

Example:
  ${SCRIPT_NAME} story/1-1-project-scaffold
  ${SCRIPT_NAME} story/1-1-project-scaffold --dry-run
USAGE
}

# --- Parse args ---------------------------------------------------------------

DRY_RUN=0
BRANCH=""

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --*)
      echo "ERROR: unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [[ -n "$BRANCH" ]]; then
        echo "ERROR: unexpected extra argument: $1" >&2
        usage
        exit 1
      fi
      BRANCH="$1"
      shift
      ;;
  esac
done

if [[ -z "$BRANCH" ]]; then
  echo "ERROR: branch name is required" >&2
  usage
  exit 1
fi

# --- Helpers ------------------------------------------------------------------

log() {
  echo "[${SCRIPT_NAME}] $*"
}

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

# --- Preflight ----------------------------------------------------------------

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: not inside a git repository" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: 'gh' (GitHub CLI) is required but not found in PATH" >&2
  exit 1
fi

if ! git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  echo "ERROR: local branch not found: ${BRANCH}" >&2
  exit 1
fi

log "Mode: $([[ $DRY_RUN -eq 1 ]] && echo 'DRY RUN' || echo 'EXECUTE')"
log "Target branch: ${BRANCH}"

# --- Step 1: Update main, verify merged (fast-forward OR squash), delete branch

log "Step 1/4: verify branch merged to main, then delete locally"

# Advance the local `main` REF before checking it out. Checking out a stale
# `main` first and pulling afterwards works from a clean tree, but aborts
# whenever local main is behind AND the working tree is dirty: git refuses the
# checkout ("your local changes would be overwritten") before the pull can run,
# even when the dirty files are identical between HEAD and origin/main. That is
# the normal case when work-in-progress is being carried across cleanup.
# Fetching into the ref is safe here because main is not the checked-out
# branch, and it fails loudly rather than silently if the update would not be a
# fast-forward.
run "git fetch origin main:main"
run "git checkout main"
run "git pull --ff-only"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] (would verify merge state of ${BRANCH} via -d, fall back to gh pr check on failure)"
  echo "[dry-run] git branch -d ${BRANCH}  # (or -D if squash-merged PR confirmed)"
else
  # Try the safe delete first. Succeeds for fast-forward merges where the
  # branch tip is an ancestor of main.
  if git branch -d "${BRANCH}" 2>/dev/null; then
    log "  branch deleted (fast-forward merge confirmed)"
  else
    # Safe delete refused. Check whether a merged PR exists with this branch
    # as head. If yes, the work is in main via squash — force-delete is safe.
    log "  fast-forward check failed; checking for merged PR with head=${BRANCH}"
    MERGED_PR_NUM="$(gh pr list \
      --head "${BRANCH}" \
      --state merged \
      --json number \
      --jq '.[0].number' \
      2>/dev/null || true)"

    if [[ -n "${MERGED_PR_NUM}" && "${MERGED_PR_NUM}" != "null" ]]; then
      log "  merged PR #${MERGED_PR_NUM} confirmed for ${BRANCH} — force-deleting"
      git branch -D "${BRANCH}"
    else
      echo "ERROR: ${BRANCH} is not merged to main and has no merged PR." >&2
      echo "       Refusing to delete. Verify the branch state manually." >&2
      exit 1
    fi
  fi
fi

# --- Step 2: Clear stale Stage 6 marker ---------------------------------------

log "Step 2/4: clear stale Stage 6 marker"

# Normal flow: post-commit hook clears it. This catches interrupted-commit
# edge cases. A marker surviving to cleanup would fail Stage 0 on the next
# story, so clear it here rather than making the next story diagnose it.
if [[ -f ".claude/.stage-6-active" ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] rm .claude/.stage-6-active"
  else
    rm -f .claude/.stage-6-active
    log "  (cleared stale Stage 6 marker)"
  fi
else
  log "  (no marker present, skipping)"
fi

# --- Step 3: Clear scratchpad -------------------------------------------------

log "Step 3/4: clear ${SCRATCHPAD_PATH}"

if [[ -f "$SCRATCHPAD_PATH" ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] : > ${SCRATCHPAD_PATH}"
  else
    : > "$SCRATCHPAD_PATH"
  fi
else
  log "  (no scratchpad file present, skipping)"
fi

# --- Step 4: [PROJECT] Post-merge deploy/migration hook -----------------------

log "Step 4/4: post-merge deploy/migration hook"

if [[ -z "$PROD_MIGRATION_WORKFLOW" ]]; then
  log "  (PROD_MIGRATION_WORKFLOW unset — no production migration"
  log "   workflow yet. Set it at the top of this script once one exists.)"
else
  run "gh workflow run ${PROD_MIGRATION_WORKFLOW}"
fi

log "Done."
log ""
log "If this was the last story of an epic, also run:"
log "  /bmad-retrospective -H <epic>        # mandatory in this framework"
log "  /bmad-project-context                # audit intent, prune AGENTS.md"
log "  triage _bmad-output/implementation-artifacts/deferred-work.md"
