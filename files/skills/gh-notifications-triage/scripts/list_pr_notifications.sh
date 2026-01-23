#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
List GitHub notification threads for Pull Requests (ignores issues) as JSON.

Usage:
  list_pr_notifications.sh [--owner OWNER ...] [--all] [--participating] [--since ISO8601] [--before ISO8601]

Examples:
  list_pr_notifications.sh
  list_pr_notifications.sh --owner akuityio --owner openai
  list_pr_notifications.sh --since 2026-01-01T00:00:00Z
EOF
}

owners=()
all="false"
participating="false"
since=""
before=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner|--org)
      owners+=("${2:-}")
      shift 2
      ;;
    --all)
      all="true"
      shift
      ;;
    --participating)
      participating="true"
      shift
      ;;
    --since)
      since="${2:-}"
      shift 2
      ;;
    --before)
      before="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

owners_json="[]"
if [[ ${#owners[@]} -gt 0 ]]; then
  owners_json="$(printf '%s\n' "${owners[@]}" | jq -R . | jq -s .)"
fi

args=(
  -H "Accept: application/vnd.github+json"
  -X GET
  /notifications
  -f per_page=50
  -f all="$all"
  -f participating="$participating"
  --paginate
  --slurp
)
if [[ -n "$since" ]]; then
  args+=(-f since="$since")
fi
if [[ -n "$before" ]]; then
  args+=(-f before="$before")
fi

gh api "${args[@]}" | jq --argjson owners "$owners_json" '
  flatten
  | map(select(.subject.type == "PullRequest"))
  | map(
      . as $n
      | ($n.subject.url | capture("/pulls/(?<n>[0-9]+)$").n | tonumber) as $pr_number
      | {
          thread_id: $n.id,
          repo: $n.repository.full_name,
          owner: $n.repository.owner.login,
          pr_number: $pr_number,
          pr_title: $n.subject.title,
          pr_url: ("https://github.com/" + $n.repository.full_name + "/pull/" + ($pr_number|tostring)),
          notification_reason: $n.reason,
          updated_at: $n.updated_at
        }
    )
  | (if ($owners|length) > 0 then map(select(.owner as $o | $owners | index($o))) else . end)
  | sort_by(.updated_at) | reverse
'

