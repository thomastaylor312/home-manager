#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
List directories in ~/Movies available for processing.

Usage:
  list_source_dirs.sh [--path PATH]

Options:
  --path PATH    Base directory to scan (default: ~/Movies)

Output:
  JSON array of directory info including name, file count, and total size.

Examples:
  list_source_dirs.sh
  list_source_dirs.sh --path /Volumes/External/Rips
EOF
}

base_path="$HOME/Movies"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      base_path="${2:-}"
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

if [[ ! -d "$base_path" ]]; then
  echo "Error: Directory not found: $base_path" >&2
  exit 1
fi

# Find directories and output as JSON
find "$base_path" -mindepth 1 -maxdepth 1 -type d | sort | while read -r dir; do
  name=$(basename "$dir")

  # Count media files (mkv, mp4, avi, etc.)
  file_count=$(find "$dir" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" \) 2>/dev/null | wc -l | tr -d ' ')

  # Get total size in bytes
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    total_bytes=$(find "$dir" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" \) -exec stat -f%z {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')
  else
    # Linux
    total_bytes=$(find "$dir" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" \) -exec stat --printf="%s\n" {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')
  fi

  # Format size for display
  if [[ $total_bytes -ge 1073741824 ]]; then
    size_human=$(awk "BEGIN {printf \"%.1f GB\", $total_bytes/1073741824}")
  elif [[ $total_bytes -ge 1048576 ]]; then
    size_human=$(awk "BEGIN {printf \"%.1f MB\", $total_bytes/1048576}")
  else
    size_human=$(awk "BEGIN {printf \"%.1f KB\", $total_bytes/1024}")
  fi

  jq -n \
    --arg name "$name" \
    --arg path "$dir" \
    --argjson file_count "$file_count" \
    --argjson total_bytes "$total_bytes" \
    --arg size_human "$size_human" \
    '{name: $name, path: $path, file_count: $file_count, total_bytes: $total_bytes, size_human: $size_human}'
done | jq -s '.'
