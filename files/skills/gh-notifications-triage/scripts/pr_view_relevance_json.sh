#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Fetch classification-friendly PR metadata (compact JSON) using `gh pr view`.

This script is intentionally generic: it exposes common "relevance signals" (direct review request,
viewer participation, @mentions in comments) without baking in any specific criteria.

Usage:
  pr_view_relevance_json.sh [--viewer LOGIN] OWNER/REPO PR_NUMBER
  pr_view_relevance_json.sh [--viewer LOGIN] OWNER/REPO PR_NUMBER THREAD_ID NOTIFICATION_REASON

Examples:
  pr_view_relevance_json.sh --viewer alice org/repo 123
  pr_view_relevance_json.sh --viewer alice org/repo 123 22180782087 review_requested
EOF
}

viewer_login=""
thread_id=""
notification_reason=""

viewer_login="${VIEWER_LOGIN:-}"

positional=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --viewer)
      viewer_login="${2:-}"
      shift 2
      ;;
    -*)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
    *)
      positional+=("$1")
      shift
      ;;
  esac
done

if [[ ${#positional[@]} -ne 2 && ${#positional[@]} -ne 4 ]]; then
  usage
  exit 2
fi

repo="${positional[0]}"
number="${positional[1]}"
if [[ ${#positional[@]} -eq 4 ]]; then
  thread_id="${positional[2]}"
  notification_reason="${positional[3]}"
fi

gh pr view -R "$repo" "$number" \
  --json number,title,body,author,labels,reviewRequests,isDraft,state,url,comments,reviews \
  | jq -c \
      --arg repo "$repo" \
      --arg thread_id "$thread_id" \
      --arg notification_reason "$notification_reason" \
      --arg viewer "$viewer_login" '
      def norm(s): (s // "") | ascii_downcase;
      def body_excerpt:
        ((.body // "")
          | gsub("\r"; "")
          | (split("\n\n")[0] // "")
          | (gsub("\n"; " ") | gsub("\\s+"; " ") | ltrimstr(" ") | rtrimstr(" "))
          | .[0:240]);

      def review_requests_slim:
        (.reviewRequests | map({__typename, login:(.login? // null), slug:(.slug? // null), name:(.name? // null)}));

      def direct_review_requested:
        ($viewer != "") and any(.reviewRequests[]?; (.__typename == "User" and (.login? // "") == $viewer));

      def viewer_commented:
        ($viewer != "") and (
          any(.comments[]?; (.viewerDidAuthor == true))
          or any(.comments[]?; ((.author.login // "") == $viewer))
        );

      def viewer_reviewed:
        ($viewer != "") and any(.reviews[]?; ((.author.login // "") == $viewer));

      def viewer_mentioned_in_comments:
        ($viewer != "") and any(.comments[]?; ((.body // "") | test("@" + $viewer + "(\\b|$)"; "i")));

      {
        thread_id: (if ($thread_id | length) > 0 then $thread_id else null end),
        notification_reason: (if ($notification_reason | length) > 0 then $notification_reason else null end),

        repo: $repo,
        number: .number,
        title: .title,
        url: .url,
        author: (.author.login // null),
        state: .state,
        isDraft: .isDraft,
        labels: (.labels | map(.name)),

        reviewRequests: review_requests_slim,
        body_excerpt: body_excerpt,

        viewer: (if ($viewer | length) > 0 then $viewer else null end),
        direct_review_requested: direct_review_requested,
        viewer_commented: viewer_commented,
        viewer_reviewed: viewer_reviewed,
        viewer_mentioned_in_comments: viewer_mentioned_in_comments
      }
    '
