#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Generate a rename plan for media files (dry-run mode).

Organizes files in place within the source directory, creating a Jellyfin-compatible
structure (Movies/ or Shows/ subdirectory) for later processing with Handbrake.

Usage:
  generate_rename_plan.sh --type TYPE --source DIR --title TITLE --year YEAR [OPTIONS]

Required Options:
  --type TYPE           Content type: movie or tv
  --source DIR          Source directory containing media files
  --title TITLE         Movie or show title
  --year YEAR           Release year

TV Show Options:
  --season N            Season number (required for TV)
  --episode-mapping FILE  JSON file with episode/extras mapping (optional)

Common Options:
  --output FILE         Output file for rename plan (default: stdout)

Output Structure:
  Movies:  SOURCE_DIR/Movies/Title (Year)/Title (Year).mkv
  TV:      SOURCE_DIR/Shows/Title (Year)/Season XX/Title SxxEyy.mkv

Episode Mapping JSON format:
{
  "episodes": [
    {"source_file": "title_t00.mkv", "episode_number": 1},
    {"source_file": "title_t03.mkv", "episode_number": 2}
  ],
  "extras": [
    {"source_file": "title_t06.mkv", "category": "trailers"}
  ]
}

If no episode mapping is provided for TV shows, files will be sorted by duration
and assigned episodes in order (which may not be correct - manual review recommended).

Examples:
  # Movie
  generate_rename_plan.sh --type movie --source ~/Movies/TheMatrix --title "The Matrix" --year 1999

  # TV Show with mapping
  generate_rename_plan.sh --type tv --source ~/Movies/Andor --title "Andor" --year 2022 --season 1 --episode-mapping mapping.json

  # TV Show auto-assignment (needs review)
  generate_rename_plan.sh --type tv --source ~/Movies/Andor --title "Andor" --year 2022 --season 1
EOF
}

content_type=""
source_dir=""
title=""
year=""
season=""
episode_mapping=""
output_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      content_type="${2:-}"
      shift 2
      ;;
    --source)
      source_dir="${2:-}"
      shift 2
      ;;
    --title)
      title="${2:-}"
      shift 2
      ;;
    --year)
      year="${2:-}"
      shift 2
      ;;
    --season)
      season="${2:-}"
      shift 2
      ;;
    --episode-mapping)
      episode_mapping="${2:-}"
      shift 2
      ;;
    --output)
      output_file="${2:-}"
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

# Validate required arguments
if [[ -z "$content_type" ]]; then
  echo "Error: --type is required" >&2
  exit 2
fi

if [[ "$content_type" != "movie" && "$content_type" != "tv" ]]; then
  echo "Error: --type must be 'movie' or 'tv'" >&2
  exit 2
fi

if [[ -z "$source_dir" ]]; then
  echo "Error: --source is required" >&2
  exit 2
fi

if [[ ! -d "$source_dir" ]]; then
  echo "Error: Source directory not found: $source_dir" >&2
  exit 1
fi

if [[ -z "$title" ]]; then
  echo "Error: --title is required" >&2
  exit 2
fi

if [[ -z "$year" ]]; then
  echo "Error: --year is required" >&2
  exit 2
fi

if [[ "$content_type" == "tv" && -z "$season" ]]; then
  echo "Error: --season is required for TV shows" >&2
  exit 2
fi

# Clean title for filesystem (remove special characters)
clean_title=$(echo "$title" | sed 's/[<>:"/\\|?*]//g' | sed 's/  */ /g')

# Build destination paths - organize in place within source directory
if [[ "$content_type" == "movie" ]]; then
  dest_dir="${source_dir}/Movies/${clean_title} (${year})"
  main_filename="${clean_title} (${year})"
else
  dest_dir="${source_dir}/Shows/${clean_title} (${year})/Season $(printf '%02d' "$season")"
fi

# Scan source files (only files directly in source_dir, not in subdirectories)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Custom scan that only looks at top-level files to avoid picking up already-organized content
files_json=$(find "$source_dir" -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" \) | sort | while read -r file; do
  filename=$(basename "$file")

  # Get file size
  if [[ "$OSTYPE" == "darwin"* ]]; then
    file_size=$(stat -f%z "$file" 2>/dev/null || echo "0")
  else
    file_size=$(stat --printf="%s" "$file" 2>/dev/null || echo "0")
  fi

  # Get metadata using ffprobe
  probe_output=$(ffprobe -v quiet -print_format json -show_format -show_streams "$file" 2>/dev/null || echo '{}')

  # Extract duration
  duration_seconds=$(echo "$probe_output" | jq -r '.format.duration // "0"' | cut -d. -f1)
  if [[ -z "$duration_seconds" || "$duration_seconds" == "null" ]]; then
    duration_seconds=0
  fi

  # Format duration as HH:MM:SS
  hours=$((duration_seconds / 3600))
  minutes=$(((duration_seconds % 3600) / 60))
  seconds=$((duration_seconds % 60))
  duration_human=$(printf "%d:%02d:%02d" "$hours" "$minutes" "$seconds")

  # Extract embedded title from format tags
  embedded_title=$(echo "$probe_output" | jq -r '.format.tags.title // .format.tags.TITLE // ""')

  # Count subtitle tracks and get languages
  subtitle_info=$(echo "$probe_output" | jq -c '
    [.streams[]? | select(.codec_type == "subtitle")] |
    {
      count: length,
      languages: [.[].tags?.language // "und"] | unique
    }
  ')

  # Output JSON for this file
  jq -n \
    --arg filename "$filename" \
    --arg path "$file" \
    --argjson duration_seconds "$duration_seconds" \
    --arg duration_human "$duration_human" \
    --arg embedded_title "$embedded_title" \
    --argjson subtitle_info "$subtitle_info" \
    --argjson file_size_bytes "$file_size" \
    '{
      filename: $filename,
      path: $path,
      duration_seconds: $duration_seconds,
      duration_human: $duration_human,
      embedded_title: $embedded_title,
      subtitle_tracks: $subtitle_info,
      file_size_bytes: $file_size_bytes
    }'
done | jq -s 'sort_by(.duration_seconds) | reverse')

# Check if we found any files
if [[ $(echo "$files_json" | jq 'length') -eq 0 ]]; then
  echo "Error: No media files found in top level of: $source_dir" >&2
  echo "Note: Only scanning top-level files, not subdirectories." >&2
  exit 1
fi

# Generate rename plan
generate_movie_plan() {
  local files="$1"

  # Find the longest file (main feature)
  local main_file
  main_file=$(echo "$files" | jq -r '.[0].path')
  local main_ext
  main_ext=$(echo "$main_file" | sed 's/.*\.//')

  # Start building the plan
  local plan='{"type": "movie", "source_dir": "", "dest_dir": "", "title": "", "year": "", "operations": []}'
  plan=$(echo "$plan" | jq \
    --arg source "$source_dir" \
    --arg dest "$dest_dir" \
    --arg title "$title" \
    --arg year "$year" \
    '.source_dir = $source | .dest_dir = $dest | .title = $title | .year = $year')

  # Process each file
  local operations='[]'
  local is_first=true

  while IFS= read -r file_info; do
    local src_path
    src_path=$(echo "$file_info" | jq -r '.path')
    local filename
    filename=$(echo "$file_info" | jq -r '.filename')
    local duration
    duration=$(echo "$file_info" | jq -r '.duration_seconds')
    local embedded_title
    embedded_title=$(echo "$file_info" | jq -r '.embedded_title')
    local ext
    ext="${filename##*.}"

    local dest_path
    local category

    if [[ "$is_first" == "true" ]]; then
      # Main feature
      dest_path="${dest_dir}/${main_filename}.${ext}"
      category="main"
      is_first=false
    else
      # Classify as extra based on duration and title
      category=$(classify_extra "$duration" "$embedded_title")
      dest_path="${dest_dir}/${category}/${filename}"
    fi

    operations=$(echo "$operations" | jq \
      --arg src "$src_path" \
      --arg dest "$dest_path" \
      --arg category "$category" \
      --argjson duration "$duration" \
      --arg embedded_title "$embedded_title" \
      '. + [{
        source: $src,
        destination: $dest,
        category: $category,
        duration_seconds: $duration,
        embedded_title: $embedded_title
      }]')
  done < <(echo "$files" | jq -c '.[]')

  echo "$plan" | jq --argjson ops "$operations" '.operations = $ops'
}

generate_tv_plan() {
  local files="$1"
  local mapping_file="$2"

  local plan='{"type": "tv", "source_dir": "", "dest_dir": "", "title": "", "year": "", "season": 0, "operations": []}'
  plan=$(echo "$plan" | jq \
    --arg source "$source_dir" \
    --arg dest "$dest_dir" \
    --arg title "$title" \
    --arg year "$year" \
    --argjson season "$season" \
    '.source_dir = $source | .dest_dir = $dest | .title = $title | .year = $year | .season = $season')

  local operations='[]'

  if [[ -n "$mapping_file" && -f "$mapping_file" ]]; then
    # Use provided episode mapping
    local mapping
    mapping=$(cat "$mapping_file")

    # Process episodes
    while IFS= read -r ep_info; do
      local src_file
      src_file=$(echo "$ep_info" | jq -r '.source_file')
      local ep_num
      ep_num=$(echo "$ep_info" | jq -r '.episode_number')

      # Find file info
      local file_info
      file_info=$(echo "$files" | jq --arg f "$src_file" '.[] | select(.filename == $f)')

      if [[ -n "$file_info" ]]; then
        local src_path
        src_path=$(echo "$file_info" | jq -r '.path')
        local ext
        ext="${src_file##*.}"
        local dest_path
        dest_path="${dest_dir}/${clean_title} S$(printf '%02d' "$season")E$(printf '%02d' "$ep_num").${ext}"

        operations=$(echo "$operations" | jq \
          --arg src "$src_path" \
          --arg dest "$dest_path" \
          --argjson ep_num "$ep_num" \
          --argjson duration "$(echo "$file_info" | jq '.duration_seconds')" \
          '. + [{
            source: $src,
            destination: $dest,
            category: "episode",
            episode_number: $ep_num,
            duration_seconds: $duration
          }]')
      fi
    done < <(echo "$mapping" | jq -c '.episodes[]?')

    # Process extras
    while IFS= read -r extra_info; do
      local src_file
      src_file=$(echo "$extra_info" | jq -r '.source_file')
      local category
      category=$(echo "$extra_info" | jq -r '.category')

      # Find file info
      local file_info
      file_info=$(echo "$files" | jq --arg f "$src_file" '.[] | select(.filename == $f)')

      if [[ -n "$file_info" ]]; then
        local src_path
        src_path=$(echo "$file_info" | jq -r '.path')
        local dest_path
        dest_path="${dest_dir}/${category}/${src_file}"

        operations=$(echo "$operations" | jq \
          --arg src "$src_path" \
          --arg dest "$dest_path" \
          --arg category "$category" \
          --argjson duration "$(echo "$file_info" | jq '.duration_seconds')" \
          '. + [{
            source: $src,
            destination: $dest,
            category: $category,
            duration_seconds: $duration
          }]')
      fi
    done < <(echo "$mapping" | jq -c '.extras[]?')

  else
    # Auto-assign episodes by duration (longest files first)
    # This is a fallback - manual mapping is recommended
    local ep_num=1

    while IFS= read -r file_info; do
      local src_path
      src_path=$(echo "$file_info" | jq -r '.path')
      local filename
      filename=$(echo "$file_info" | jq -r '.filename')
      local duration
      duration=$(echo "$file_info" | jq -r '.duration_seconds')
      local embedded_title
      embedded_title=$(echo "$file_info" | jq -r '.embedded_title')
      local ext
      ext="${filename##*.}"

      # Heuristic: files over 20 minutes are likely episodes
      if [[ "$duration" -ge 1200 ]]; then
        local dest_path
        dest_path="${dest_dir}/${clean_title} S$(printf '%02d' "$season")E$(printf '%02d' "$ep_num").${ext}"

        operations=$(echo "$operations" | jq \
          --arg src "$src_path" \
          --arg dest "$dest_path" \
          --argjson ep_num "$ep_num" \
          --argjson duration "$duration" \
          --arg embedded_title "$embedded_title" \
          --arg note "AUTO-ASSIGNED - please verify episode order" \
          '. + [{
            source: $src,
            destination: $dest,
            category: "episode",
            episode_number: $ep_num,
            duration_seconds: $duration,
            embedded_title: $embedded_title,
            needs_review: true,
            note: $note
          }]')
        ep_num=$((ep_num + 1))
      else
        # Classify as extra
        local category
        category=$(classify_extra "$duration" "$embedded_title")
        local dest_path
        dest_path="${dest_dir}/${category}/${filename}"

        operations=$(echo "$operations" | jq \
          --arg src "$src_path" \
          --arg dest "$dest_path" \
          --arg category "$category" \
          --argjson duration "$duration" \
          --arg embedded_title "$embedded_title" \
          '. + [{
            source: $src,
            destination: $dest,
            category: $category,
            duration_seconds: $duration,
            embedded_title: $embedded_title
          }]')
      fi
    done < <(echo "$files" | jq -c '.[]')
  fi

  echo "$plan" | jq --argjson ops "$operations" '.operations = $ops'
}

classify_extra() {
  local duration="$1"
  local embedded_title="$2"
  local title_lower
  title_lower=$(echo "$embedded_title" | tr '[:upper:]' '[:lower:]')

  # Duration in seconds
  if [[ "$duration" -lt 180 ]]; then
    # Under 3 minutes = trailer
    echo "trailers"
  elif [[ "$duration" -lt 600 ]]; then
    # 3-10 minutes
    if [[ "$title_lower" == *"interview"* ]]; then
      echo "interviews"
    else
      echo "featurettes"
    fi
  elif [[ "$duration" -lt 1800 ]]; then
    # 10-30 minutes
    if [[ "$title_lower" == *"behind"* || "$title_lower" == *"making"* ]]; then
      echo "behind the scenes"
    elif [[ "$title_lower" == *"deleted"* ]]; then
      echo "deleted scenes"
    else
      echo "featurettes"
    fi
  elif [[ "$duration" -lt 3600 ]]; then
    # 30-60 minutes
    echo "featurettes"
  else
    # Over 60 minutes - needs user review
    echo "extras"
  fi
}

# Export function for subshells
export -f classify_extra

# Generate the plan
if [[ "$content_type" == "movie" ]]; then
  plan=$(generate_movie_plan "$files_json")
else
  plan=$(generate_tv_plan "$files_json" "$episode_mapping")
fi

# Output
if [[ -n "$output_file" ]]; then
  echo "$plan" | jq '.' > "$output_file"
  echo "Rename plan written to: $output_file" >&2
else
  echo "$plan" | jq '.'
fi
