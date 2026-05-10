FROM python:3.11-slim

# ---- system deps ----
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    gcc \
    sqlite3 \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# ---- environment ----
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONPATH=/app/app:${PYTHONPATH}



# ---- python deps ----
RUN pip install --upgrade pip

RUN pip install \
    fastapi \
    uvicorn[standard] \
    python-dotenv \
    pydantic \
    aiosqlite \
    ollama \
    pydantic-ai

# NOTE:
# pydantic-ai installs providers (openai/groq/anthropic) via extras in some versions
# If needed, explicitly add:
# RUN pip install pydantic-ai[openai,groq,anthropic]

# ---- copy app ----
RUN useradd -u 1000 -ms /bin/bash appuser
COPY --chown=1000:1000 . /app
USER appuser
WORKDIR /app
# ---- runtime ----
EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
