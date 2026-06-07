#!/usr/bin/env python3
import argparse
import time
from pathlib import Path

import pymysql
import requests


def format_table(columns, rows) -> str:
    if not rows:
        return "(empty result)\n"
    data = [[str(x) for x in row] for row in rows]
    widths = [len(str(c)) for c in columns]
    for row in data:
        for i, value in enumerate(row):
            widths[i] = max(widths[i], min(len(value), 80))
    sep = "+" + "+".join("-" * (w + 2) for w in widths) + "+"
    out = [sep]
    out.append("| " + " | ".join(str(c).ljust(widths[i]) for i, c in enumerate(columns)) + " |")
    out.append(sep)
    for row in data:
        out.append("| " + " | ".join(value[:80].ljust(widths[i]) for i, value in enumerate(row)) + " |")
    out.append(sep)
    return "\n".join(out) + "\n"


def run_query(conn, query: str):
    start = time.perf_counter()
    with conn.cursor() as cur:
        cur.execute(query)
        rows = cur.fetchall()
        columns = [d[0] for d in cur.description] if cur.description else []
    elapsed_ms = (time.perf_counter() - start) * 1000
    return columns, rows, elapsed_ms


def write_result(path: Path, title: str, query: str, columns, rows, elapsed_ms: float) -> None:
    with path.open("w", encoding="utf-8") as f:
        f.write(f"# {title}\n\n")
        f.write("## Query\n")
        f.write(query.strip() + "\n\n")
        f.write("## Result\n")
        if columns:
            f.write(format_table(columns, rows))
        else:
            f.write("OK\n")
        f.write(f"\n## Time\n{elapsed_ms:.3f} ms\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="Run IDZ-5 Manticore checks and save text outputs.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=9306)
    parser.add_argument("--http-url", default="http://localhost:9308")
    parser.add_argument("--checks-dir", default="checks")
    args = parser.parse_args()

    checks = Path(args.checks_dir)
    checks.mkdir(parents=True, exist_ok=True)

    conn = pymysql.connect(host=args.host, port=args.port, user="", password="", database="Manticore", charset="utf8mb4", autocommit=True)

    # Connectivity
    mysql_cols, mysql_rows, mysql_ms = run_query(conn, "SHOW TABLES")
    http_start = time.perf_counter()
    http_resp = requests.post(f"{args.http_url}/sql", data={"query": "SHOW TABLES"}, timeout=30)
    http_ms = (time.perf_counter() - http_start) * 1000
    with (checks / "connectivity.txt").open("w", encoding="utf-8") as f:
        f.write("# Connectivity check\n\n")
        f.write("## MySQL protocol\n")
        f.write("Command: mysql -h 127.0.0.1 -P 9306 -e 'SHOW TABLES;'\n")
        f.write(format_table(mysql_cols, mysql_rows))
        f.write(f"Time: {mysql_ms:.3f} ms\n\n")
        f.write("## HTTP API\n")
        f.write('Command: curl -s http://localhost:9308/sql -d "query=SHOW TABLES"\n')
        f.write(http_resp.text + "\n")
        f.write(f"Time: {http_ms:.3f} ms\n")

    queries = [
        ("basic_search.txt", "Basic search", """
SELECT id, title, WEIGHT() AS w
FROM products
WHERE MATCH('wireless bluetooth headphones')
ORDER BY w DESC
LIMIT 10
"""),
        ("phrase_search.txt", "Exact phrase search", """
SELECT id, title, WEIGHT() AS w
FROM products
WHERE MATCH('"noise cancelling"')
LIMIT 10
"""),
        ("proximity_search.txt", "Proximity search", """
SELECT id, title, WEIGHT() AS w
FROM products
WHERE MATCH('"portable speaker"~3')
LIMIT 10
"""),
        ("filtered_search.txt", "Filtered search", """
SELECT id, title, price, rating
FROM products
WHERE MATCH('laptop') AND price BETWEEN 30000 AND 80000 AND rating >= 4.0
ORDER BY rating DESC
LIMIT 10
"""),
        ("json_search.txt", "JSON attribute search", """
SELECT id, title, tags
FROM products
WHERE MATCH('phone') AND tags.color = 'black'
LIMIT 10
"""),
    ]

    for filename, title, query in queries:
        cols, rows, ms = run_query(conn, query)
        write_result(checks / filename, title, query, cols, rows, ms)

    facet_query = """
SELECT category, COUNT(*) AS cnt, AVG(price) AS avg_price
FROM products
WHERE MATCH('gaming')
GROUP BY category
ORDER BY cnt DESC
"""
    cols, rows, ms = run_query(conn, facet_query)
    write_result(checks / "facets.txt", "Facet aggregation by category", facet_query, cols, rows, ms)

    upd_queries = [
        "SELECT id, title, price, rating FROM products WHERE id = 1",
        "UPDATE products SET price = 9999.99, rating = 4.9 WHERE id = 1",
        "SELECT id, title, price, rating FROM products WHERE id = 1",
        "SELECT id, title FROM products WHERE id = 2",
        "DELETE FROM products WHERE id = 2",
        "SELECT id, title FROM products WHERE id = 2",
        """
REPLACE INTO products (id, title, description, category, brand, price, rating, reviews_count, in_stock, tags, created_at)
VALUES (2, 'Replaced Noise Cancelling Headphones', 'Replaced document for UPDATE DELETE REPLACE demonstration', 'audio', 'DemoBrand', 12999.00, 4.8, 777, 1, '{"color":"black","wireless":true,"demo":"replace"}', 1710000000)
""",
        "SELECT id, title, price, rating, tags FROM products WHERE id = 2",
    ]
    with (checks / "update_delete.txt").open("w", encoding="utf-8") as f:
        f.write("# UPDATE / DELETE / REPLACE\n\n")
        for q in upd_queries:
            cols, rows, ms = run_query(conn, q)
            f.write("## Query\n")
            f.write(q.strip() + "\n\n")
            f.write("## Result\n")
            if cols:
                f.write(format_table(cols, rows))
            else:
                f.write("OK\n")
            f.write(f"Time: {ms:.3f} ms\n\n")

    cols, rows, ms = run_query(conn, "SELECT COUNT(*) AS total FROM products")
    write_result(checks / "count.txt", "Loaded rows count", "SELECT COUNT(*) AS total FROM products", cols, rows, ms)

    conn.close()
    print(f"Checks saved to {checks}")


if __name__ == "__main__":
    main()
