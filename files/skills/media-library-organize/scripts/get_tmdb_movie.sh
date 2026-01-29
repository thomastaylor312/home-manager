#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Get movie details from TMDB.

Usage:
  get_tmdb_movie.sh MOVIE_ID

Environment:
  TMDB_API_TOKEN    Required. Get one at https://www.themoviedb.org/settings/api

Output:
  JSON object with movie details including title, year, runtime, and genres.

Examples:
  get_tmdb_movie.sh 603    # The Matrix
  get_tmdb_movie.sh 155    # The Dark Knight
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

movie_id="$1"

if [[ -z "${TMDB_API_TOKEN:-}" ]]; then
  echo "Error: TMDB_API_TOKEN environment variable not set" >&2
  echo "Get one at https://www.themoviedb.org/settings/api" >&2
  exit 1
fi

# Make API request
response=$(curl -s --fail \
  -H "Authorization: Bearer ${TMDB_API_TOKEN}" \
  -H "Accept: application/json" \
  "https://api.themoviedb.org/3/movie/${movie_id}?language=en-US" 2>/dev/null)

if [[ -z "$response" ]]; then
  echo "Error: Failed to get movie details from TMDB" >&2
  exit 1
fi

# Transform response
echo "$response" | jq '{
  id: .id,
  title: .title,
  original_title: .original_title,
  year: (.release_date // "" | split("-")[0]),
  release_date: .release_date,
  runtime_minutes: .runtime,
  overview: .overview,
  genres: [.genres[].name],
  tagline: .tagline,
  imdb_id: .imdb_id,
  poster_path: (if .poster_path then "https://image.tmdb.org/t/p/w500" + .poster_path else null end)
}'
