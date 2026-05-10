#!/bin/bash


MEETING_NAME=$1
MODEL=$2

if [ -z "$MEETING_NAME" ] || [ -z "$MODEL" ]; then
  echo "Usage: <name> <model>"
  exit 1
fi

echo "Starting Whisper for meeting ${MEETING_NAME} with model: $MODEL"

# Run the Whisper command with the specified model
python3 -m whisper /input/${MEETING_NAME}.wav  --model $MODEL --output_format txt --output_dir /output
