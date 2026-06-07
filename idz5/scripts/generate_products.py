#!/usr/bin/env python3
import argparse
import csv
import json
import random
import time
from pathlib import Path
from faker import Faker
from tqdm import tqdm

CATEGORIES = [
    "audio", "phones", "laptops", "gaming", "home", "sports", "books",
    "camera", "wearables", "accessories", "kitchen", "office"
]
BRANDS = [
    "Sony", "Samsung", "Apple", "Lenovo", "Asus", "Acer", "Xiaomi", "Philips",
    "HyperX", "Logitech", "JBL", "Anker", "Dell", "HP", "MSI", "DemoBrand"
]
COLORS = ["black", "white", "red", "blue", "green", "silver", "gray"]
KEYWORDS = [
    "wireless", "bluetooth", "headphones", "noise cancelling", "portable speaker",
    "laptop", "gaming", "phone", "charger", "keyboard", "mouse", "monitor",
    "smart watch", "camera", "usb type c", "fast charging", "home office"
]

# Первые записи фиксированные: по ним удобно проверять запросы и UPDATE/DELETE/REPLACE.
FIXED_PRODUCTS = [
    {
        "id": 1,
        "title": "Wireless Bluetooth Headphones Black Edition",
        "description": "Comfortable wireless bluetooth headphones with strong bass and long battery life.",
        "category": "audio",
        "brand": "Sony",
        "price": 7499.0,
        "rating": 4.7,
        "reviews_count": 1450,
        "in_stock": True,
        "tags": {"color": "black", "wireless": True, "bluetooth": True},
    },
    {
        "id": 2,
        "title": "Premium Noise Cancelling Headphones",
        "description": "Over-ear headphones with active noise cancelling and bluetooth connectivity.",
        "category": "audio",
        "brand": "JBL",
        "price": 11999.0,
        "rating": 4.6,
        "reviews_count": 980,
        "in_stock": True,
        "tags": {"color": "black", "wireless": True, "anc": True},
    },
    {
        "id": 3,
        "title": "Compact Portable Bluetooth Speaker",
        "description": "A portable waterproof speaker for travel, music and parties.",
        "category": "audio",
        "brand": "Anker",
        "price": 4999.0,
        "rating": 4.5,
        "reviews_count": 2030,
        "in_stock": True,
        "tags": {"color": "blue", "portable": True, "bluetooth": True},
    },
    {
        "id": 4,
        "title": "Gaming Laptop RTX Performance",
        "description": "Powerful gaming laptop with high refresh display and mechanical keyboard feel.",
        "category": "laptops",
        "brand": "MSI",
        "price": 74999.0,
        "rating": 4.8,
        "reviews_count": 760,
        "in_stock": True,
        "tags": {"color": "black", "gaming": True, "gpu": "rtx"},
    },
    {
        "id": 5,
        "title": "Black Smartphone With Fast Charging",
        "description": "Modern phone with black body, large screen and fast charging support.",
        "category": "phones",
        "brand": "Samsung",
        "price": 39999.0,
        "rating": 4.4,
        "reviews_count": 1890,
        "in_stock": True,
        "tags": {"color": "black", "phone": True, "fast_charging": True},
    },
]


def make_product(fake: Faker, product_id: int) -> dict:
    category = random.choice(CATEGORIES)
    brand = random.choice(BRANDS)
    color = random.choice(COLORS)
    keyword_pack = random.sample(KEYWORDS, k=random.randint(2, 5))

    # Принудительно добавляем нужные слова, чтобы лабораторные запросы стабильно давали результаты.
    if product_id % 20 == 0:
        keyword_pack += ["wireless", "bluetooth", "headphones"]
        category = "audio"
    if product_id % 33 == 0:
        keyword_pack += ["noise cancelling"]
        category = "audio"
    if product_id % 40 == 0:
        keyword_pack += ["portable speaker"]
        category = "audio"
    if product_id % 25 == 0:
        keyword_pack += ["laptop"]
        category = "laptops"
    if product_id % 18 == 0:
        keyword_pack += ["gaming"]
        category = random.choice(["gaming", "laptops", "accessories"])
    if product_id % 21 == 0:
        keyword_pack += ["phone"]
        category = "phones"
        color = "black"

    unique_keywords = list(dict.fromkeys(keyword_pack))
    title = f"{brand} {color.title()} {' '.join(unique_keywords[:3]).title()}"
    description = (
        f"{fake.sentence(nb_words=10)} Product includes {' '.join(unique_keywords)}. "
        f"Suitable for daily usage, office, travel and gaming scenarios. <b>HTML promo text</b>."
    )

    return {
        "id": product_id,
        "title": title,
        "description": description,
        "category": category,
        "brand": brand,
        "price": round(random.uniform(500, 150000), 2),
        "rating": round(random.uniform(2.5, 5.0), 1),
        "reviews_count": random.randint(0, 5000),
        "in_stock": random.choice([True, True, True, False]),
        "tags": {
            "color": color,
            "keywords": unique_keywords,
            "wireless": "wireless" in unique_keywords,
            "gaming": "gaming" in unique_keywords,
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate synthetic product catalog for IDZ-5.")
    parser.add_argument("--count", type=int, default=100_000, help="Number of products to generate")
    parser.add_argument("--seed", type=int, default=81, help="Random seed")
    parser.add_argument("--out-dir", default="data", help="Output directory")
    args = parser.parse_args()

    if args.count < len(FIXED_PRODUCTS):
        raise ValueError("count must be at least number of fixed products")

    random.seed(args.seed)
    fake = Faker("en_US")
    Faker.seed(args.seed)

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    ndjson_path = out_dir / "products.ndjson"
    csv_path = out_dir / "products_pg.csv"

    base_ts = int(time.time()) - 365 * 24 * 3600

    with ndjson_path.open("w", encoding="utf-8") as ndjson_file, csv_path.open("w", encoding="utf-8", newline="") as csv_file:
        fieldnames = [
            "id", "title", "description", "category", "brand", "price", "rating",
            "reviews_count", "in_stock", "tags", "created_at"
        ]
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writeheader()

        for product_id in tqdm(range(1, args.count + 1), desc="Generating products"):
            if product_id <= len(FIXED_PRODUCTS):
                product = dict(FIXED_PRODUCTS[product_id - 1])
            else:
                product = make_product(fake, product_id)

            product["created_at"] = base_ts + product_id
            ndjson_file.write(json.dumps(product, ensure_ascii=False) + "\n")

            csv_row = dict(product)
            csv_row["tags"] = json.dumps(product["tags"], ensure_ascii=False)
            writer.writerow(csv_row)

    print(f"Generated {args.count} products")
    print(f"Manticore NDJSON: {ndjson_path}")
    print(f"PostgreSQL CSV:   {csv_path}")


if __name__ == "__main__":
    main()
