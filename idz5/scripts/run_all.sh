#!/usr/bin/env bash
set -euo pipefail

COUNT="${1:-100000}"

mkdir -p checks data

echo "[1/8] Starting Docker services"
docker compose --profile tools up -d

echo "[2/8] Installing Python dependencies"
python3 -m pip install -r scripts/requirements.txt

echo "[3/8] Creating Manticore RT-index"
python3 - <<'PY'
from pathlib import Path
import pymysql
sql = Path('sql/01_create_index.sql').read_text(encoding='utf-8')
conn = pymysql.connect(host='127.0.0.1', port=9306, user='', password='', database='Manticore', autocommit=True)
with conn.cursor() as cur:
    for stmt in [s.strip() for s in sql.split(';') if s.strip()]:
        print('SQL>', stmt[:120].replace('\n', ' '))
        cur.execute(stmt)
conn.close()
PY

echo "[4/8] Generating ${COUNT} products"
python3 scripts/generate_products.py --count "$COUNT" --out-dir data

echo "[5/8] Loading products to ManticoreSearch"
python3 scripts/load_manticore.py --file data/products.ndjson

echo "[6/8] Running Manticore checks"
python3 scripts/run_manticore_checks.py

echo "[7/8] Loading products to PostgreSQL"
python3 scripts/load_postgres.py --file data/products_pg.csv

echo "[8/8] Running PostgreSQL comparison"
python3 scripts/run_pg_comparison.py

echo "Done. Check files are in ./checks"
