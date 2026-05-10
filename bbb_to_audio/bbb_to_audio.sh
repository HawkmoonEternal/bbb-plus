#!/bin/bash
set -e

URL="$1"
OUTPUT="$2"

if [ -z "$URL" ] || [ -z "$OUTPUT" ]; then
  echo "Usage: <url> <output-name>"
  exit 1
fi

echo "Downloading from: $URL"
echo "Output base name: $OUTPUT"

# Step 1: download audio
yt-dlp -x --audio-format wav -o "/output/.${OUTPUT}.wav" "$URL"

# Step 2: convert to Whisper format (16kHz, stereo PCM)
ffmpeg -y \
  -i "/output/.${OUTPUT}.wav" \
  -ar 16000 \
  -ac 2 \
  -c:a pcm_s16le \
  "/output/${OUTPUT}.wav"

# Step 3: remove tmp file
rm -rf /output/.${OUTPUT}.wav

echo "Done: ${OUTPUT}.wav"

