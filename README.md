# AI Meeting Summary

This repository contains a containerized pipeline for downloading a BigBlueButton meeting recording, transcribing it with Whisper, and generating a structured meeting summary using an LLM backend.

## Project Overview

The pipeline is composed of three main services orchestrated by `docker compose`:

- `bbb_to_audio`: downloads audio from a BigBlueButton meeting URL and saves it to `bbb_to_audio/output`
- `audio_to_transcript`: transcribes audio files using Whisper and writes transcripts to `audio_to_transcript/output`
- `transcript_to_summary`: processes transcript text, generates a summary, and exports the result to `transcript_to_summary/output`
- `ollama`: runs the local LLM inference engine used by the summarization service when choosing the `ollama` provider

A wrapper script, `generate_summary.sh`, starts the services, triggers each stage, and waits for the final summary file.

## Directory Structure

- `bbb_to_audio/`
  - `bbb_to_audio.sh`: audio extraction wrapper script
  - `Dockerfile`: service container definition
  - `main.py`: FastAPI wrapper that launches the audio extraction pipeline
  - `output/`: generated audio files

- `audio_to_transcript/`
  - `audio_to_transcript.sh`: transcription wrapper script
  - `Dockerfile`: service container definition
  - `main.py`: FastAPI wrapper that launches Whisper transcription
  - `whisper-data/`: cached Whisper model files
  - `output/`: generated transcript files

- `transcript_to_summary/`
  - `transcript_to_summary.sh`: summary pipeline wrapper script
  - `Dockerfile`: service container definition
  - `app/`: FastAPI summary API, DB, and transcript processor
  - `output/`: generated summary text files
  - `ollama-data/`: Ollama persistent data and models

- `docker-compose.yml`: service orchestration
- `generate_summary.sh`: high-level entrypoint for the full workflow

## Requirements

- Docker
- Docker Compose
- `curl`

## Setup

Ensure the script is executable:

```bash
chmod +x generate_summary.sh
```

No manual Docker setup is needed—the script handles `docker compose up` and `docker compose down` automatically.

## Usage

Use `generate_summary.sh` to run the full pipeline with a meeting URL and summarization configuration. The script will start the services, orchestrate the pipeline stages, and clean up when complete.

Example:

```bash
./generate_summary.sh \
  --url https://example.com \
  --meeting-name test \
  --provider openai \
  --model gpt-4.1-mini \
  --whisper-model small \
  --api-key sk-xxx \
  --custom-prompt "Generate a summary of the meeting transcript."
```

### Parameters

- `--url`: BigBlueButton meeting recording URL
- `--meeting-name`: identifier for the meeting, used for file names and lookup
- `--provider`: LLM provider name (e.g. `openai`, `ollama`)
- `--model`: LLM model name (e.g. `gpt-4.1-mini`, `llama3`)
- `--whisper-model`: Whisper transcription model (e.g. `small`)
- `--api-key`: API key for the chosen provider
- `--custom-prompt`: custom context to guide the summary generation

## Service Endpoints

The services expose the following endpoints:

- `POST http://localhost:9000/run`
  - body: `{ "url": "<meeting_url>", "name": "<meeting_name>" }`
  - downloads audio from the meeting

- `POST http://localhost:9001/run`
  - body: `{ "model": "<whisper_model>", "name": "<meeting_name>" }`
  - transcribes the downloaded audio file

- `POST http://localhost:9002/save-model-config`
  - configures model/provider settings for summary generation

- `POST http://localhost:9002/process-transcript`
  - body includes `model`, `model_name`, `meeting_id`, `chunk_size`, `overlap`, `custom_prompt`
  - starts summary generation for the transcript

- `GET http://localhost:9002/get-summary/<meeting_id>`
  - retrieves summary status and writes the final text output into `transcript_to_summary/output/<meeting_id>.txt`

## Output Files

- `bbb_to_audio/output/`: extracted audio files from BBB meetings
- `audio_to_transcript/output/`: transcript `.txt` files generated from audio
- `transcript_to_summary/output/`: final summary `.txt` files

## Notes

- The pipeline is entirely self-contained within `generate_summary.sh`—it starts containers, runs all stages, and shuts down when finished.
- Containers are configured to listen on:
  - `bbb-to-audio` on port `9000`
  - `audio-to-transcript` on port `9001`
  - `transcript-to-summary` on port `9002`
  - `ollama` on port `11434`
- The summary API stores transcript and processing state in an internal SQLite-backed database via `transcript_to_summary/app/db.py`.
- For manual testing or debugging individual services, you can start containers separately with `docker compose up -d` and send requests directly to the service endpoints.
- If you need to debug or extend the service, the FastAPI apps are located in `bbb_to_audio/main.py`, `audio_to_transcript/main.py`, and `transcript_to_summary/app/main.py`.
- See `https://github.com/openai/whisper` for a list of available whisper models.
- The pipeline was tested with provider `openai` and model `gpt-4.1-mini` providing decent results (requiring API key and paid access). Using the local `mistral` model from `ollama` produces garbage. Larger local models might work better but haven't been tested so far.

## Stop and Cleanup

The `generate_summary.sh` script automatically shuts down services when complete. If services are running manually:

```bash
docker compose down
```

## License
This project is licensed under the MIT License.

See the `LICENSE` file for full license details.