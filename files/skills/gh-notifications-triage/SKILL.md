---
name: gh-notifications-triage
description: Triage GitHub notifications by filtering to Pull Request notifications (ignoring issues), optionally filtering by organization/owner names, summarizing PRs via `gh pr view`, classifying relevance based on user-provided criteria, and marking “not relevant” PR notification threads as read via `gh api` (without approving, closing, or merging PRs).
---

# GitHub Notifications Triage (PRs only)

## Preconditions

- `gh auth status` succeeds for `github.com`
- `jq` is installed

## Interactive flow (follow this exactly)

1. Ask: “Filter by any organization/owner names? (comma-separated, blank for no filter)”
2. Ask: “Give me a short criteria prompt for what counts as ‘not relevant to you’.”
3. List PR notifications (ignore issues) using `gh api`:

   - No owner filter:
     - `files/skills/gh-notifications-triage/scripts/list_pr_notifications.sh`
   - With owner filters:
     - `files/skills/gh-notifications-triage/scripts/list_pr_notifications.sh --owner github --owner foobar`

4. For each PR notification, fetch PR details (for summarization/classification) using `gh pr view`:

   - Single PR:
     - `files/skills/gh-notifications-triage/scripts/pr_view_json.sh org/repo 10076`
   - Many PRs (example: run up to 10 at a time):
     - `files/skills/gh-notifications-triage/scripts/list_pr_notifications.sh --owner github | jq -r '.[] | "\(.repo) \(.pr_number)"' | head -n 30 | xargs -n2 -P 10 files/skills/gh-notifications-triage/scripts/pr_view_json.sh`

   - If your criteria depends on “who’s involved” (direct review request vs team, did the viewer comment/review, @mentions in comments), use:
     - `files/skills/gh-notifications-triage/scripts/pr_view_relevance_json.sh [--viewer LOGIN] org/repo 10076 [THREAD_ID NOTIFICATION_REASON]`
     - For batch use (keeps 1 PR = 1 JSON line), include the notification thread fields and set `VIEWER_LOGIN` once:
       - `export VIEWER_LOGIN="$(gh api user --jq .login)"`
       - `files/skills/gh-notifications-triage/scripts/list_pr_notifications.sh --owner github | jq -r '.[] | "\(.repo) \(.pr_number) \(.thread_id) \(.notification_reason)"' | head -n 30 | xargs -n4 -P 10 files/skills/gh-notifications-triage/scripts/pr_view_relevance_json.sh`

5. Batch classification (required):

   - Split PRs into chunks of 10.
   - For each chunk, delegate to a separate subagent/task (run in parallel if possible) to:
     - Produce a 1–3 sentence “summary of the PR” from the `gh pr view` output.
     - Classify using the user’s criteria into exactly one bucket:
       - `not_relevant_high` (only if you are highly confident)
       - `not_relevant_medium` (some signals, but not enough to auto-mark-read)
       - `other` (everything else)
   - NEVER place anything in `not_relevant_high` unless you’re confident enough that auto-marking as read is correct.

6. Present results back to the user in three lists (`not_relevant_high`, `not_relevant_medium`, `other`).

   Each item must include: `repo`, `PR number`, `PR title`, and “summary of the PR”.

7. Ask: “Any PRs miscategorized? Tell me which ones (repo#number) and where to move them.”

8. After the user confirms categorization, mark the “not relevant” PR notification threads as read (DO NOT approve/close/merge PRs):

   - If you’re unsure whether to mark `not_relevant_medium` as read, ask:
     - “Mark as read: (1) high only, or (2) high + medium?”
     - Default to (2) unless the user says otherwise.

   - Mark one thread as read:
     - `files/skills/gh-notifications-triage/scripts/mark_thread_read.sh 22180782087`
   - Mark many threads as read (from a JSON object you produced):
     - High only:
       - `jq -r '.not_relevant_high[].thread_id' results.json | xargs -n1 files/skills/gh-notifications-triage/scripts/mark_thread_read.sh`
     - High + medium:
       - `jq -r '(.not_relevant_high + .not_relevant_medium)[]?.thread_id' results.json | xargs -n1 files/skills/gh-notifications-triage/scripts/mark_thread_read.sh`

## Output format (recommended)

When presenting lists in chat, also keep a machine-readable artifact in memory (or on disk) shaped like:

```json
{
  "not_relevant_high": [
    { "thread_id": "22180782087", "repo": "org/repo", "pr_number": 123, "pr_title": "…", "summary": "…" }
  ],
  "not_relevant_medium": [],
  "other": []
}
```

REQUIRED: Once threads are marked as read, the artifact should be removed.

## Required `gh api` endpoints (copy/paste)

- List notifications (docs: `GET /notifications`):
  - `gh api -X GET /notifications -f per_page=50 -f all=false -f participating=false --paginate --slurp`
- Mark a thread as read (docs: `PATCH /notifications/threads/{thread_id}`):
  - `gh api -X PATCH /notifications/threads/THREAD_ID`

## Notes on `gh api` (avoid common mistakes)

- Adding `-f/-F` parameters defaults `gh api` to `POST`; force `GET` with `-X GET` when calling `GET /notifications`.
- With `--paginate --slurp`, `gh api` returns an “array of pages”; `files/skills/gh-notifications-triage/scripts/list_pr_notifications.sh` uses `jq flatten` to combine them.

## Notes on `gh pr view --json` shapes (useful for classification lookups)

- `.reviewRequests` is an array of `User` and/or `Team` objects; check `.__typename` to distinguish direct review requests from team/group requests.
- `.comments` is an array; comment objects include `.author.login`, `.body`, and `.viewerDidAuthor` (useful to detect “I commented” without needing the login).
- `.reviews` is an array; review objects include `.author.login` and `.state` but do not include `.viewerDidAuthor` (to detect “I reviewed”, compare `.author.login` to the viewer login).
- If you’re unsure what a field looks like for a specific PR, inspect keys directly:
  - `gh pr view -R org/repo 123 --json comments --jq '.comments[0] | keys'`
  - `gh pr view -R org/repo 123 --json reviewRequests --jq '.reviewRequests[0] | keys'`
  - `gh pr view -R org/repo 123 --json reviews --jq '.reviews[0] | keys'`

## Safety constraints (non-negotiable)

- Do not approve, merge, close, or edit PRs.
- Only call `PATCH /notifications/threads/{thread_id}` after the user confirms categorization.
