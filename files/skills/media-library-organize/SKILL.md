---
name: media-library-organize
description: Organize MakeMKV-ripped media files into Jellyfin-compatible naming conventions. Supports movies and TV shows with interactive episode matching using duration analysis and subtitle extraction.
---

# Media Library Organization

Organize MakeMKV-ripped media files from `~/Movies` into Jellyfin-compatible structure. Supports both movies and TV shows, with interactive episode matching using duration analysis and subtitle extraction.

## Preconditions

- `ffmpeg` and `ffprobe` are installed
- `jq` is installed
- `curl` is installed
- `tesseract` is installed (for OCR of image-based subtitles)
- TMDB API token is set: `export TMDB_API_TOKEN="your_token"` (get one at https://www.themoviedb.org/settings/api)

## Target Naming Conventions

**Movies:**
```
~/Movies/Dir/Movies/Movie Name (Year)/Movie Name (Year).mkv
~/Movies/Dir/Movies/Movie Name (Year)/trailers/
~/Movies/Dir/Movies/Movie Name (Year)/featurettes/
~/Movies/Dir/Movies/Movie Name (Year)/behind the scenes/
```

**TV Shows:**
```
~/Movies/Dir/Shows/Show Name (Year)/Season XX/Show Name SxxEyy.mkv
~/Movies/Dir/Shows/Show Name (Year)/Season XX/extras/
```

## Interactive Flow

### 1. Check TMDB API Token

```bash
if [[ -z "$TMDB_API_TOKEN" ]]; then
  echo "TMDB_API_TOKEN not set. Get one at https://www.themoviedb.org/settings/api"
  # Prompt user to set it
fi
```

### 2. List Source Directories

```bash
files/skills/media-library-organize/scripts/list_source_dirs.sh
```

Shows available directories in `~/Movies` with file counts and total sizes.

### 3. Select Directory and Content Type

Ask user:
- Which directory to process?
- Is this a Movie or TV Show?
- For TV shows: Which season number?

### 4. Scan Media Files

```bash
files/skills/media-library-organize/scripts/scan_media_files.sh ~/Movies/SelectedDirectory
```

Returns JSON with duration, embedded title, and subtitle track info for each file.

### 5. Search TMDB

```bash
# Search for content
files/skills/media-library-organize/scripts/search_tmdb.sh --type movie "Movie Name"
files/skills/media-library-organize/scripts/search_tmdb.sh --type tv "Show Name"

# Get details
files/skills/media-library-organize/scripts/get_tmdb_movie.sh MOVIE_ID
files/skills/media-library-organize/scripts/get_tmdb_season.sh TV_ID SEASON_NUMBER
```

Confirm the correct match with the user.

### 6. Episode Classification (TV Shows Only)

For TV shows, classify files into main content vs extras:

1. Get typical episode runtime from TMDB
2. Files within 20% of typical runtime = main content candidates
3. Files significantly shorter = extras

Extract subtitle previews for episode matching:
```bash
files/skills/media-library-organize/scripts/extract_subtitle_preview.sh ~/Movies/Dir/title_t00.mkv
```

### 7. Generate Rename Plan

```bash
# For movies
files/skills/media-library-organize/scripts/generate_rename_plan.sh \
  --type movie \
  --source ~/Movies/SelectedDirectory \
  --title "Movie Name" \
  --year 2024

# For TV shows (with episode mapping JSON)
files/skills/media-library-organize/scripts/generate_rename_plan.sh \
  --type tv \
  --source ~/Movies/SelectedDirectory \
  --title "Show Name" \
  --year 2024 \
  --season 1 \
  --episode-mapping episode_mapping.json
```

Episode mapping JSON format:
```json
{
  "episodes": [
    {"source_file": "title_t00.mkv", "episode_number": 1},
    {"source_file": "title_t03.mkv", "episode_number": 2}
  ],
  "extras": [
    {"source_file": "title_t06.mkv", "category": "trailers"}
  ]
}
```

### 8. Review and Confirm

Present the complete rename plan showing:
```
Source                              -> Destination
~/Movies/Dir/title_t00.mkv          -> ~/Movies/Dir/Shows/Show (2024)/Season 01/Show S01E01.mkv
~/Movies/Dir/title_t03.mkv          -> ~/Movies/Dir/Shows/Show (2024)/Season 01/Show S01E02.mkv
~/Movies/Dir/title_t06.mkv          -> ~/Movies/Dir/Shows/Show (2024)/Season 01/trailers/title_t06.mkv
```

Ask for confirmation before proceeding.

### 9. Execute Rename Plan

```bash
files/skills/media-library-organize/scripts/execute_rename_plan.sh rename_plan.json
```

## Extras Auto-Categorization

Based on duration and embedded MKV title metadata:

| Duration  | Keywords in Title  | Target Subdirectory  |
| --------- | ------------------ | -------------------- |
| < 3 min   | (any)              | `trailers/`          |
| 3-10 min  | "interview"        | `interviews/`        |
| 3-10 min  | (other)            | `featurettes/`       |
| 10-30 min | "behind", "making" | `behind the scenes/` |
| 10-30 min | "deleted"          | `deleted scenes/`    |
| 30-60 min | (any)              | `featurettes/`       |
| > 60 min  | (prompt user)      | ask user             |

## Episode Matching Strategy

**WARNING**: Track order on Blu-rays is often scrambled. We've seen Disc 1 contain episodes
in order 3, 1, 2 instead of 1, 2, 3. Always verify episodes visually or via subtitle content.

Use multiple signals:

1. **Duration variance**: Match files to TMDB's typical runtimes
2. **Runtime precision matching**: Compare exact file durations against TMDB per-episode runtimes - some episodes vary by 1-2 minutes which can help narrow down candidates
3. **Subtitle extraction**: Extract first 60 seconds, search for episode title keywords (see PGS workaround below)
4. **MKV metadata**: Check embedded title tags
5. **Filename hints**: Parse any episode numbers from source filenames
6. **Chapter count analysis**: Different episodes may have different chapter structures
   ```bash
   ffprobe -v quiet -print_format json -show_chapters input.mkv | jq '.chapters | length'
   ```
7. **Visual identification**: Extract frames at key timestamps and identify by distinctive scenes

Present proposed mapping with confidence indicators and allow user to reorder before execution.

### PGS Subtitle Workaround

Blu-ray discs typically use PGS (Presentation Graphic Stream) subtitles which are image-based,
not text. The `extract_subtitle_preview.sh` script will fail for these. Alternative approaches:

1. **Frame extraction with overlay**: Extract frames with subtitles burned in:
   ```bash
   ffmpeg -y -ss 60 -i input.mkv -filter_complex "[0:v][0:s:0]overlay" -frames:v 1 -update 1 frame.png
   ```

2. **OCR the frames**: Use tesseract to extract text:
   ```bash
   tesseract frame.png stdout
   ```

3. **Visual identification**: Extract frames at key timestamps (60s, 180s, 1200s) and
   visually identify episodes by distinctive scenes, locations, or characters.

### Analysis Output (Recommended)

For complex disc sets, create an `EPISODE_ANALYSIS.md` file in the source directory documenting:
- Confirmed episode mappings with identification method
- Uncertain files with visual clues and candidate episodes
- Chapter counts and precise runtimes for all files
- TMDB episode reference for cross-checking

### Additional Sampling for Uncertain Episodes

When initial identification yields LOW or MEDIUM confidence, extract frames at multiple
timestamps throughout the episode to find distinctive visual cues:

```bash
# Extract frames at 2min, 5min, 10min, 15min, 20min, 25min, 30min, 35min, 40min
for ts in 120 300 600 900 1200 1500 1800 2100 2400; do
  ffmpeg -y -ss $ts -i input.mkv -frames:v 1 -q:v 2 "frame_${ts}s.jpg" 2>/dev/null
done
```

**What to look for:**
- Location changes (ship interior vs Earth vs alien planet vs flashback)
- Character costumes or appearance changes
- Distinctive set pieces, props, or visual effects
- Environmental differences (lighting, weather, terrain)
- Dream/hallucination sequences with unusual visual treatment

**Process:**
1. Extract 5-9 frames spread across the episode runtime
2. Compare visual elements against TMDB episode descriptions
3. Look for episode-specific events (battles, ceremonies, specific locations)
4. Upgrade confidence when visual evidence confirms identification
5. For persistent uncertainty, try different timestamp intervals

## Safety Constraints

- Never overwrite existing files without explicit confirmation
- Always show complete rename plan before execution
- Use `mv` (not copy) to avoid duplicating large files
- Only scans top-level files in source directory (ignores subdirectories to avoid re-processing)
