#!/usr/bin/env python3
import argparse
import time
from pathlib import Path

import psycopg2


def main() -> None:
    parser = argparse.ArgumentParser(description="Run PostgreSQL full-text comparison query and save result.")
    parser.add_argument("--dsn", default="dbname=idz5 user=idz5 password=idz5 host=localhost port=5432")
    parser.add_argument("--out", default="checks/pg_vs_manticore.txt")
    args = parser.parse_args()

    query = """
SELECT title, ts_rank(tsv, q) AS rank
FROM pg_products, to_tsquery('english', 'wireless & bluetooth & headphones') q
WHERE tsv @@ q
ORDER BY rank DESC
LIMIT 10;
"""
    explain = "EXPLAIN ANALYZE " + query

    conn = psycopg2.connect(args.dsn)
    with conn.cursor() as cur:
        start = time.perf_counter()
        cur.execute(query)
        rows = cur.fetchall()
        elapsed_ms = (time.perf_counter() - start) * 1000

        cur.execute(explain)
        explain_rows = cur.fetchall()

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8") as f:
        f.write("# PostgreSQL vs ManticoreSearch\n\n")
        f.write("## PostgreSQL query\n")
        f.write(query.strip() + "\n\n")
        f.write("## PostgreSQL result\n")
        for row in rows:
            f.write(f"{row}\n")
        f.write(f"\nMeasured by Python: {elapsed_ms:.3f} ms\n\n")
        f.write("## EXPLAIN ANALYZE\n")
        for row in explain_rows:
            f.write(row[0] + "\n")
        f.write("\n## ManticoreSearch value\n")
        f.write("Сюда вписать время из checks/basic_search.txt.\n")

    conn.close()
    print(f"Saved PostgreSQL comparison to {out}")


if __name__ == "__main__":
    main()
