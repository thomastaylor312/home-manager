#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Mark a GitHub notification thread as done using `gh api`.

Note: GitHub’s “Done” action is implemented by marking the notification thread as read via
`PATCH /notifications/threads/{thread_id}`.

Usage:
  mark_thread_done.sh [--dry-run] THREAD_ID

Examples:
  mark_thread_done.sh 22180782087
  mark_thread_done.sh --dry-run 22180782087
EOF
}

dry_run="false"
case "${1:-}" in
  -h|--help|"")
    usage
    exit 0
    ;;
esac

if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run="true"
  shift
fi

thread_id="${1:-}"
if [[ "$thread_id" == "-h" || "$thread_id" == "--help" ]]; then
  usage
  exit 0
fi
if [[ -z "$thread_id" ]]; then
  usage
  exit 2
fi

endpoint="/notifications/threads/${thread_id}"
cmd=(gh api -H "Accept: application/vnd.github+json" -X DELETE "$endpoint" --silent)

if [[ "$dry_run" == "true" ]]; then
  printf '%q ' "${cmd[@]}"
  printf '\n'
  exit 0
fi

"${cmd[@]}"

