#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Scan media files in a directory and extract metadata using ffprobe.

Usage:
  scan_media_files.sh DIRECTORY

Output:
  JSON array of file info including:
  - filename
  - path
  - duration_seconds
  - duration_human (HH:MM:SS)
  - embedded_title (from MKV metadata)
  - subtitle_tracks (count and languages)
  - chapter_count
  - file_size_bytes

Examples:
  scan_media_files.sh ~/Movies/MyDisc
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

directory="$1"

if [[ ! -d "$directory" ]]; then
  echo "Error: Directory not found: $directory" >&2
  exit 1
fi

# Check for ffprobe
if ! command -v ffprobe &>/dev/null; then
  echo "Error: ffprobe not found. Please install ffmpeg." >&2
  exit 1
fi

# Find and process media files
find "$directory" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" \) | sort | while read -r file; do
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

  # Get chapter count
  chapter_count=$(ffprobe -v quiet -print_format json -show_chapters "$file" 2>/dev/null | jq '.chapters | length')
  if [[ -z "$chapter_count" || "$chapter_count" == "null" ]]; then
    chapter_count=0
  fi

  # Output JSON for this file
  jq -n \
    --arg filename "$filename" \
    --arg path "$file" \
    --argjson duration_seconds "$duration_seconds" \
    --arg duration_human "$duration_human" \
    --arg embedded_title "$embedded_title" \
    --argjson subtitle_info "$subtitle_info" \
    --argjson chapter_count "$chapter_count" \
    --argjson file_size_bytes "$file_size" \
    '{
      filename: $filename,
      path: $path,
      duration_seconds: $duration_seconds,
      duration_human: $duration_human,
      embedded_title: $embedded_title,
      subtitle_tracks: $subtitle_info,
      chapter_count: $chapter_count,
      file_size_bytes: $file_size_bytes
    }'
done | jq -s 'sort_by(.duration_seconds) | reverse'
