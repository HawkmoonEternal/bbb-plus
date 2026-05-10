# Use a lightweight Python image
FROM docker.io/python:3.10-slim

# Set environment variables for pip
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DEFAULT_TIMEOUT=600 \
    PIP_RETRIES=20

# Set cache dirs
ENV XDG_CACHE_HOME=/app/cache \
    HF_HOME=/app/cache/huggingface \
    WHISPER_CACHE_DIR=/app/cache/whisper

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libsndfile1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install pip packages with extended timeout and retries
RUN pip install --upgrade pip && \
    pip install torch --extra-index-url https://download.pytorch.org/whl/cpu && \
    pip install git+https://github.com/openai/whisper.git

RUN pip install fastapi uvicorn

# Copy the entrypoint script into the container
RUN useradd -u 1000 -ms /bin/bash appuser
RUN mkdir -p /app/cache/whisper && chown -R 1000:1000 /app/cache && chmod -R 775 /app/cache

COPY --chown=1000:1000 audio_to_transcript.sh /app/audio_to_transcript.sh
RUN chmod +x /app/audio_to_transcript.sh

COPY --chown=1000:1000 main.py /app/main.py

USER appuser

WORKDIR /app

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]