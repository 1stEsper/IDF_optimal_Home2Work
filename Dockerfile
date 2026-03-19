FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY pyproject.toml uv.lock ./

RUN uv sync --frozen --no-cache


COPY . .

RUN chmod +x run_pipeline.sh

ENV GOOGLE_APPLICATION_CREDENTIALS="/app/credentials/idf-analysis-0a1db53d06ba.json"
ENV DBT_PROFILES_DIR="/app/transform"


ENTRYPOINT ["./run_pipeline.sh"]


