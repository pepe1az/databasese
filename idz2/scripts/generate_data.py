import csv
import random
from datetime import datetime, timedelta
from pathlib import Path

OUT = Path("orders_flat.csv")
ROWS = 1_000_000

regions = ["Moscow", "Saint Petersburg", "Kazan", "Novosibirsk", "Ekaterinburg"]
categories = ["Electronics", "Books", "Clothes", "Home", "Sport"]
statuses = ["new", "paid", "shipped", "cancelled", "refunded"]

products = {
    "Electronics": ["Smartphone", "Laptop", "Headphones", "Monitor", "Keyboard"],
    "Books": ["SQL Book", "Linux Book", "Python Book", "DevOps Book", "Algorithms Book"],
    "Clothes": ["T-Shirt", "Jeans", "Jacket", "Sneakers", "Hoodie"],
    "Home": ["Chair", "Table", "Lamp", "Vacuum Cleaner", "Kettle"],
    "Sport": ["Dumbbells", "Bike", "Yoga Mat", "Treadmill", "Backpack"],
}

start = datetime.now() - timedelta(days=365)

with OUT.open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)

    for i in range(1, ROWS + 1):
        category = random.choice(categories)
        product_name = random.choice(products[category])
        product_id = abs(hash(product_name)) % 100000
        customer_id = random.randint(1, 50000)
        customer_name = f"Customer {customer_id}"
        customer_email = f"user{customer_id}@example.com"
        region = random.choice(regions)

        quantity = random.randint(1, 5)
        price = round(random.uniform(300, 150000), 2)
        line_total = round(quantity * price, 2)

        dt = start + timedelta(seconds=random.randint(0, 365 * 24 * 3600))
        order_date = dt.date().isoformat()
        order_datetime = dt.strftime("%Y-%m-%d %H:%M:%S")

        writer.writerow([
            order_date,
            order_datetime,
            i,
            customer_id,
            customer_name,
            customer_email,
            region,
            product_id,
            product_name,
            category,
            quantity,
            price,
            line_total,
            random.choice(statuses),
        ])

print(f"Generated {ROWS} rows into {OUT}")
