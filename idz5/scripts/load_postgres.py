#!/usr/bin/env python3
import argparse
import csv
import json
from pathlib import Path

import psycopg2
from psycopg2.extras import execute_values, Json
from tqdm import tqdm


def read_rows(path: Path):
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            yield (
                int(row["id"]),
                row["title"],
                row["description"],
                row["category"],
                row["brand"],
                float(row["price"]),
                float(row["rating"]),
                int(row["reviews_count"]),
                row["in_stock"].lower() == "true",
                Json(json.loads(row["tags"])),
                int(row["created_at"]),
            )


def batched(iterable, size):
    batch = []
    for item in iterable:
        batch.append(item)
        if len(batch) >= size:
            yield batch
            batch = []
    if batch:
        yield batch


def main() -> None:
    parser = argparse.ArgumentParser(description="Load generated products into PostgreSQL.")
    parser.add_argument("--file", default="data/products_pg.csv", help="Input CSV file")
    parser.add_argument("--dsn", default="dbname=idz5 user=idz5 password=idz5 host=localhost port=5432", help="PostgreSQL DSN")
    parser.add_argument("--batch-size", type=int, default=2000)
    args = parser.parse_args()

    path = Path(args.file)
    if not path.exists():
        raise FileNotFoundError(f"Input file not found: {path}. Run scripts/generate_products.py first.")

    conn = psycopg2.connect(args.dsn)
    conn.autocommit = True
    with conn.cursor() as cur:
        cur.execute("DROP TABLE IF EXISTS pg_products")
        cur.execute("""
            CREATE TABLE pg_products (
                id            bigint PRIMARY KEY,
                title         text,
                description   text,
                category      text,
                brand         text,
                price         numeric,
                rating        numeric,
                reviews_count integer,
                in_stock      boolean,
                tags          jsonb,
                created_at    timestamp
            )
        """)

    total = sum(1 for _ in path.open("r", encoding="utf-8")) - 1
    insert_sql = """
        INSERT INTO pg_products
        (id, title, description, category, brand, price, rating, reviews_count, in_stock, tags, created_at)
        VALUES %s
    """
    template = "(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,to_timestamp(%s))"

    with conn.cursor() as cur:
        for batch in tqdm(batched(read_rows(path), args.batch_size), total=(total + args.batch_size - 1) // args.batch_size, desc="Loading to PostgreSQL"):
            execute_values(cur, insert_sql, batch, template=template)

        cur.execute("""
            ALTER TABLE pg_products
            ADD COLUMN tsv tsvector
            GENERATED ALWAYS AS (to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, ''))) STORED
        """)
        cur.execute("CREATE INDEX idx_pg_products_tsv ON pg_products USING GIN(tsv)")
        cur.execute("ANALYZE pg_products")
        cur.execute("SELECT COUNT(*) FROM pg_products")
        print(f"PostgreSQL rows: {cur.fetchone()[0]}")

    conn.close()


if __name__ == "__main__":
    main()
