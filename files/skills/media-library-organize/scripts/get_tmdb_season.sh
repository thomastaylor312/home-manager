#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Get TV show season details from TMDB including episode list.

Usage:
  get_tmdb_season.sh TV_ID SEASON_NUMBER

Environment:
  TMDB_API_TOKEN    Required. Get one at https://www.themoviedb.org/settings/api

Output:
  JSON object with season details including episode list with titles, numbers, and runtimes.

Examples:
  get_tmdb_season.sh 1396 1    # Breaking Bad Season 1
  get_tmdb_season.sh 105971 1  # Andor Season 1
EOF
}

if [[ $# -lt 2 ]]; then
  usage
  exit 2
fi

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

tv_id="$1"
season_number="$2"

if [[ -z "${TMDB_API_TOKEN:-}" ]]; then
  echo "Error: TMDB_API_TOKEN environment variable not set" >&2
  echo "Get one at https://www.themoviedb.org/settings/api" >&2
  exit 1
fi

# First get the show details to get the name and typical runtime
show_response=$(curl -s --fail \
  -H "Authorization: Bearer ${TMDB_API_TOKEN}" \
  -H "Accept: application/json" \
  "https://api.themoviedb.org/3/tv/${tv_id}?language=en-US" 2>/dev/null)

if [[ -z "$show_response" ]]; then
  echo "Error: Failed to get TV show details from TMDB" >&2
  exit 1
fi

# Get season details
season_response=$(curl -s --fail \
  -H "Authorization: Bearer ${TMDB_API_TOKEN}" \
  -H "Accept: application/json" \
  "https://api.themoviedb.org/3/tv/${tv_id}/season/${season_number}?language=en-US" 2>/dev/null)

if [[ -z "$season_response" ]]; then
  echo "Error: Failed to get season details from TMDB" >&2
  exit 1
fi

# Combine show and season info
jq -n \
  --argjson show "$show_response" \
  --argjson season "$season_response" \
  '{
    show_id: $show.id,
    show_title: $show.name,
    show_original_title: $show.original_name,
    show_year: ($show.first_air_date // "" | split("-")[0]),
    typical_runtime_minutes: ($show.episode_run_time[0] // null),
    season_number: $season.season_number,
    season_name: $season.name,
    episode_count: ($season.episodes | length),
    episodes: [
      $season.episodes[] | {
        episode_number: .episode_number,
        title: .name,
        air_date: .air_date,
        runtime_minutes: .runtime,
        overview: (.overview[:150] + (if (.overview | length) > 150 then "..." else "" end))
      }
    ]
  }'
