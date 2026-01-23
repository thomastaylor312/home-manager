#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Fetch PR details (JSON) using `gh pr view`.

Usage:
  pr_view_json.sh OWNER/REPO PR_NUMBER

Example:
  pr_view_json.sh akuityio/akuity-platform 10076
EOF
}

case "${1:-}" in
  -h|--help|"")
    usage
    exit 0
    ;;
esac

if [[ $# -ne 2 ]]; then
  usage
  exit 2
fi

repo="$1"
number="$2"

gh pr view -R "$repo" "$number" \
  --json number,title,body,author,additions,deletions,changedFiles,labels,reviewDecision,state,isDraft,baseRefName,headRefName,url \
  | jq -c --arg repo "$repo" '
      {
        repo: $repo,
        number: .number,
        title: .title,
        url: .url,
        author: (.author.login // null),
        state: .state,
        isDraft: .isDraft,
        baseRefName: .baseRefName,
        headRefName: .headRefName,
        additions: .additions,
        deletions: .deletions,
        changedFiles: .changedFiles,
        reviewDecision: .reviewDecision,
        labels: (.labels | map(.name)),
        body: (.body // "")
      }
    '
