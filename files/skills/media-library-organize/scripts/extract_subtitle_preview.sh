#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Extract subtitle preview from first 60 seconds of a video file.

Usage:
  extract_subtitle_preview.sh [OPTIONS] VIDEO_FILE

Options:
  --duration SECONDS    Duration to extract (default: 60)
  --track INDEX         Subtitle track index (default: 0, first subtitle track)
  --format FORMAT       Output format: text, srt, json (default: text)

Output:
  Extracted subtitle text from the first N seconds of the video.
  Useful for episode identification by matching against episode titles.

Examples:
  extract_subtitle_preview.sh ~/Movies/MyDisc/title_t00.mkv
  extract_subtitle_preview.sh --duration 120 ~/Movies/MyDisc/title_t00.mkv
  extract_subtitle_preview.sh --format json ~/Movies/MyDisc/title_t00.mkv
EOF
}

duration=60
track_index=0
output_format="text"
video_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --duration)
      duration="${2:-60}"
      shift 2
      ;;
    --track)
      track_index="${2:-0}"
      shift 2
      ;;
    --format)
      output_format="${2:-text}"
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
      video_file="$1"
      shift
      ;;
  esac
done

if [[ -z "$video_file" ]]; then
  echo "Error: Video file required" >&2
  usage
  exit 2
fi

if [[ ! -f "$video_file" ]]; then
  echo "Error: File not found: $video_file" >&2
  exit 1
fi

# Check for ffmpeg
if ! command -v ffmpeg &>/dev/null; then
  echo "Error: ffmpeg not found. Please install ffmpeg." >&2
  exit 1
fi

# Find subtitle streams
subtitle_streams=$(ffprobe -v quiet -print_format json -show_streams -select_streams s "$video_file" 2>/dev/null | jq -r '.streams | length')

if [[ "$subtitle_streams" -eq 0 ]]; then
  # No subtitles available
  if [[ "$output_format" == "json" ]]; then
    jq -n \
      --arg file "$(basename "$video_file")" \
      '{file: $file, has_subtitles: false, preview: ""}'
  else
    echo "No subtitle tracks found in: $(basename "$video_file")"
  fi
  exit 0
fi

# Create temp file for subtitle extraction
temp_srt=$(mktemp /tmp/subtitle_preview.XXXXXX.srt)
trap 'rm -f "$temp_srt"' EXIT

# Extract subtitles for the first N seconds
# Map the specified subtitle track (s:track_index) to output
ffmpeg -v quiet -y \
  -i "$video_file" \
  -t "$duration" \
  -map "0:s:${track_index}?" \
  -c:s srt \
  "$temp_srt" 2>/dev/null || true

# Check if extraction succeeded
if [[ ! -s "$temp_srt" ]]; then
  # Check if subtitles are PGS (image-based)
  codec=$(ffprobe -v quiet -print_format json -show_streams -select_streams s "$video_file" | \
    jq -r ".streams[$track_index].codec_name // \"unknown\"")

  if [[ "$output_format" == "json" ]]; then
    jq -n \
      --arg file "$(basename "$video_file")" \
      --arg codec "$codec" \
      '{file: $file, has_subtitles: true, extraction_failed: true, codec: $codec, preview: ""}'
  elif [[ "$codec" == "hdmv_pgs_subtitle" ]]; then
    echo "PGS (image-based) subtitles detected - text extraction not possible."
    echo "Try frame extraction with OCR instead:"
    echo "  ffmpeg -ss 60 -i \"$video_file\" -filter_complex '[0:v][0:s:0]overlay' -frames:v 1 -update 1 frame.png"
    echo "  tesseract frame.png stdout"
  else
    echo "Failed to extract subtitles (codec: $codec)"
  fi
  exit 0
fi

case "$output_format" in
  srt)
    cat "$temp_srt"
    ;;
  json)
    # Extract just the text content, removing SRT formatting
    subtitle_text=$(sed -e '/^[0-9]*$/d' -e '/^[0-9][0-9]:[0-9][0-9]:/d' -e '/^$/d' "$temp_srt" | head -50 | tr '\n' ' ' | sed 's/  */ /g')
    jq -n \
      --arg file "$(basename "$video_file")" \
      --arg preview "$subtitle_text" \
      --argjson duration "$duration" \
      '{file: $file, has_subtitles: true, duration_extracted: $duration, preview: $preview}'
    ;;
  text|*)
    # Strip SRT formatting, output plain text
    sed -e '/^[0-9]*$/d' -e '/^[0-9][0-9]:[0-9][0-9]:/d' -e '/^$/d' "$temp_srt" | head -50
    ;;
esac
