#!/usr/bin/env python3
import argparse
import json
import sys
import time
from pathlib import Path

import requests
from tqdm import tqdm


def chunks(items, size):
    batch = []
    for item in items:
        batch.append(item)
        if len(batch) >= size:
            yield batch
            batch = []
    if batch:
        yield batch


def read_products(path: Path):
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            if line.strip():
                yield json.loads(line)


def send_bulk(url: str, batch: list[dict]) -> None:
    lines = []
    for product in batch:
        product_id = int(product.pop("id"))
        lines.append(json.dumps({"insert": {"index": "products", "id": product_id, "doc": product}}, ensure_ascii=False))
    payload = "\n".join(lines) + "\n"
    response = requests.post(f"{url}/bulk", data=payload.encode("utf-8"), headers={"Content-Type": "application/x-ndjson"}, timeout=120)
    if response.status_code >= 400:
        print(response.text, file=sys.stderr)
        response.raise_for_status()
    data = response.json()
    if data.get("errors"):
        raise RuntimeError(f"Manticore bulk returned errors: {data}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Load generated products into ManticoreSearch via HTTP /bulk.")
    parser.add_argument("--file", default="data/products.ndjson", help="Input NDJSON file")
    parser.add_argument("--url", default="http://localhost:9308", help="Manticore HTTP URL")
    parser.add_argument("--batch-size", type=int, default=1000, help="Bulk batch size")
    args = parser.parse_args()

    path = Path(args.file)
    if not path.exists():
        raise FileNotFoundError(f"Input file not found: {path}. Run scripts/generate_products.py first.")

    total = sum(1 for _ in path.open("r", encoding="utf-8"))
    start = time.perf_counter()
    loaded = 0
    for batch in tqdm(chunks(read_products(path), args.batch_size), total=(total + args.batch_size - 1) // args.batch_size, desc="Loading to Manticore"):
        send_bulk(args.url, batch)
        loaded += len(batch)

    elapsed = time.perf_counter() - start
    print(f"Loaded {loaded} products into ManticoreSearch in {elapsed:.2f} seconds")


if __name__ == "__main__":
    main()
