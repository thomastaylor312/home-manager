#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Search TMDB for movies or TV shows.

Usage:
  search_tmdb.sh --type TYPE QUERY

Options:
  --type TYPE    Content type: movie or tv (required)
  --year YEAR    Filter by release year (optional)
  --limit N      Max results to return (default: 5)

Environment:
  TMDB_API_TOKEN    Required. Get one at https://www.themoviedb.org/settings/api

Output:
  JSON array of search results with id, title, year, and overview.

Examples:
  search_tmdb.sh --type movie "The Matrix"
  search_tmdb.sh --type tv "Breaking Bad"
  search_tmdb.sh --type movie --year 1999 "The Matrix"
EOF
}

content_type=""
year=""
limit=5
query=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      content_type="${2:-}"
      shift 2
      ;;
    --year)
      year="${2:-}"
      shift 2
      ;;
    --limit)
      limit="${2:-5}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      query="$1"
      shift
      ;;
  esac
done

if [[ -z "$content_type" ]]; then
  echo "Error: --type is required (movie or tv)" >&2
  usage
  exit 2
fi

if [[ "$content_type" != "movie" && "$content_type" != "tv" ]]; then
  echo "Error: --type must be 'movie' or 'tv'" >&2
  exit 2
fi

if [[ -z "$query" ]]; then
  echo "Error: Search query required" >&2
  usage
  exit 2
fi

if [[ -z "${TMDB_API_TOKEN:-}" ]]; then
  echo "Error: TMDB_API_TOKEN environment variable not set" >&2
  echo "Get one at https://www.themoviedb.org/settings/api" >&2
  exit 1
fi

# URL encode the query
encoded_query=$(printf '%s' "$query" | jq -sRr @uri)

# Build API URL
api_url="https://api.themoviedb.org/3/search/${content_type}?query=${encoded_query}&include_adult=false&language=en-US&page=1"

if [[ -n "$year" ]]; then
  if [[ "$content_type" == "movie" ]]; then
    api_url="${api_url}&primary_release_year=${year}"
  else
    api_url="${api_url}&first_air_date_year=${year}"
  fi
fi

# Make API request
response=$(curl -s --fail \
  -H "Authorization: Bearer ${TMDB_API_TOKEN}" \
  -H "Accept: application/json" \
  "$api_url" 2>/dev/null)

if [[ -z "$response" ]]; then
  echo "Error: Failed to query TMDB API" >&2
  exit 1
fi

# Transform response based on content type
if [[ "$content_type" == "movie" ]]; then
  echo "$response" | jq --argjson limit "$limit" '
    .results[:$limit] | map({
      id: .id,
      title: .title,
      original_title: .original_title,
      year: (.release_date // "" | split("-")[0]),
      release_date: .release_date,
      overview: (.overview[:200] + (if (.overview | length) > 200 then "..." else "" end)),
      popularity: .popularity
    })
  '
else
  echo "$response" | jq --argjson limit "$limit" '
    .results[:$limit] | map({
      id: .id,
      title: .name,
      original_title: .original_name,
      year: (.first_air_date // "" | split("-")[0]),
      first_air_date: .first_air_date,
      overview: (.overview[:200] + (if (.overview | length) > 200 then "..." else "" end)),
      popularity: .popularity
    })
  '
fi
