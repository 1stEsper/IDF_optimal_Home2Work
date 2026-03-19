#!/bin/bash
set -e

echo "Step 1: Run scripts load data from sources to Datalake(GCS)..."
uv run python3 scripts/ingest_to_gcs.py

echo "Step 2: Run scripts load data from GCS to BigQuery..."
uv run python3 scripts/GCS_to_BQ.py

echo "Step 3: Run dbt transform"
cd transform
uv run dbt build --profiles-dir .

echo "Pipeline is running succesfully!"