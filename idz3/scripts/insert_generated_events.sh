#!/usr/bin/env bash
set -euo pipefail

ROWS="${1:-100000}"

python3 scripts/generate_events.py "$ROWS" | \
  docker compose exec -T clickhouse1 clickhouse-client \
    --query "INSERT INTO events FORMAT TSV"
