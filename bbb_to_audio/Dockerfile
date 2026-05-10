FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    && pip install yt-dlp \
    && rm -rf /var/lib/apt/lists/*

RUN pip install fastapi uvicorn

RUN useradd -u 1000 -ms /bin/bash appuser

COPY --chown=1000:1000 main.py /app/main.py
COPY --chown=1000:1000 bbb_to_audio.sh /app/bbb_to_audio.sh

RUN chmod +x /app/bbb_to_audio.sh

USER appuser

WORKDIR /app

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
