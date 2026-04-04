#!/usr/bin/env bash
#
# Assembles a narrated video from screenshots + TTS audio.
#
# Prerequisites:
#   pip install edge-tts
#   apt install ffmpeg jq  (or brew install ffmpeg jq)
#
# Usage:
#   bash scripts/make_video.sh
#
# Output: tmp/video_screenshots/whatsapp_conversation.mp4

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCREENSHOTS_DIR="$PROJECT_DIR/tmp/video_screenshots"
NARRATION_FILE="$SCRIPT_DIR/video_narration.json"
AUDIO_DIR="$SCREENSHOTS_DIR/audio"
SEGMENTS_DIR="$SCREENSHOTS_DIR/segments"
OUTPUT="$SCREENSHOTS_DIR/whatsapp_conversation.mp4"

# Spanish voice — override with: VOICE=es-CO-SalomeNeural bash scripts/make_video.sh
VOICE="${VOICE:-es-AR-ElenaNeural}"

# Check prerequisites
for cmd in edge-tts ffmpeg jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Missing: $cmd"
    case $cmd in
      edge-tts) echo "   Install: pip install edge-tts" ;;
      ffmpeg)   echo "   Install: apt install ffmpeg (or brew install ffmpeg)" ;;
      jq)       echo "   Install: apt install jq (or brew install jq)" ;;
    esac
    exit 1
  fi
done

echo "Building video from screenshots + TTS narration..."
echo "   Voice: $VOICE"
echo ""

mkdir -p "$AUDIO_DIR" "$SEGMENTS_DIR"

ENTRIES=$(jq length "$NARRATION_FILE")
CONCAT_FILE="$SEGMENTS_DIR/concat.txt"
> "$CONCAT_FILE"

for i in $(seq 0 $((ENTRIES - 1))); do
  IDX=$(printf "%02d" $((i + 1)))
  SCREENSHOT=$(jq -r ".[$i].screenshot" "$NARRATION_FILE")
  DURATION=$(jq -r ".[$i].duration" "$NARRATION_FILE")
  NARRATION=$(jq -r ".[$i].narration" "$NARRATION_FILE")

  IMG="$SCREENSHOTS_DIR/$SCREENSHOT"
  AUDIO="$AUDIO_DIR/${IDX}.mp3"
  SEGMENT="$SEGMENTS_DIR/${IDX}.mp4"

  if [ ! -f "$IMG" ]; then
    echo "  Missing screenshot: $SCREENSHOT — skipping"
    continue
  fi

  # Step 1: Generate TTS audio
  echo "  [$IDX] Generating audio: ${NARRATION:0:60}..."
  edge-tts --voice "$VOICE" --text "$NARRATION" --write-media "$AUDIO" 2>/dev/null

  # Get actual audio duration (may be longer than specified minimum)
  AUDIO_DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$AUDIO")
  # Use the longer of: narration audio or specified duration
  SEGMENT_DURATION=$(python3 -c "print(max($AUDIO_DURATION + 0.5, $DURATION))")

  # Step 2: Create video segment — image + audio
  ffmpeg -y -loop 1 -i "$IMG" -i "$AUDIO" \
    -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=white" \
    -c:v libx264 -tune stillimage -pix_fmt yuv420p \
    -c:a aac -b:a 128k \
    -t "$SEGMENT_DURATION" \
    -shortest \
    "$SEGMENT" 2>/dev/null

  echo "file '$SEGMENT'" >> "$CONCAT_FILE"
done

# Step 3: Concatenate all segments
echo ""
echo "Concatenating $ENTRIES segments..."
ffmpeg -y -f concat -safe 0 -i "$CONCAT_FILE" \
  -c copy \
  "$OUTPUT" 2>/dev/null

# Cleanup
rm -rf "$AUDIO_DIR" "$SEGMENTS_DIR"

DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUTPUT" | cut -d. -f1)
SIZE=$(du -h "$OUTPUT" | cut -f1)

echo ""
echo "Video ready: $OUTPUT"
echo "   Duration: ${DURATION}s | Size: $SIZE"
