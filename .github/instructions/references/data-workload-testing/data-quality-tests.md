# Data Quality & Convention Tests Reference

## 1. Schema Validation

Validate that data transformations produce the correct structure.

```python
# tests/data/test_silver_orders.py
import pytest, json
from pydantic import BaseModel, Field, validator

class OrderSchema(BaseModel):
    order_id: str
    customer_id: str
    order_amount: float = Field(..., gt=0)
    order_date: str

    @validator('order_date')
    def validate_date_format(cls, v):
        assert len(v) == 10 and v[4] == '-' and v[7] == '-'
        return v

def test_silver_orders_schema(spark_session):
    df = spark_session.table("silver.orders")
    for record in df.toJSON().collect():
        OrderSchema(**json.loads(record))
```

## 2. Completeness (NULL Rates)

```python
def test_silver_completeness(spark_session):
    df = spark_session.table("silver.orders")
    null_thresholds = {
        'order_id': 0.0, 'customer_id': 0.0,
        'order_amount': 0.0, 'shipping_address': 0.05
    }
    for col, threshold in null_thresholds.items():
        null_rate = df.filter(f.col(col).isNull()).count() / df.count()
        assert null_rate <= threshold, f"{col}: null rate {null_rate} > {threshold}"
```

## 3. Value Ranges

```python
def test_silver_value_ranges(spark_session):
    df = spark_session.table("silver.orders")
    invalid = df.filter(
        (f.col('order_amount') < 0.01) | (f.col('order_amount') > 999999.99)
    ).count()
    assert invalid == 0, f"Found {invalid} invalid amounts"

    future_dates = df.withColumn(
        'age_days', f.datediff(f.current_date(), f.col('order_date'))
    ).filter(f.col('age_days') < 0).count()
    assert future_dates == 0, f"Found {future_dates} orders with future dates"
```

## 4. Uniqueness

```python
def test_silver_uniqueness(spark_session):
    df = spark_session.table("silver.products")
    duplicates = df.groupBy('product_id').count().filter('count > 1').count()
    assert duplicates == 0, f"Found {duplicates} duplicate product IDs"
```

## 5. Referential Integrity (SQL)

```sql
-- tests/data/silver_referential_integrity.sql
SELECT COUNT(*) as orphaned_records
FROM silver.order_items oi
LEFT JOIN silver.orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
HAVING COUNT(*) > 0;
-- Expected: 0 orphaned records
```

## 6. Naming & Partitioning Conventions

```python
import re

def test_column_naming(spark_session):
    df = spark_session.table("silver.orders")
    pattern = re.compile(r'^[a-z][a-z0-9_]*$')
    for field in df.schema.fields:
        assert pattern.match(field.name), f"'{field.name}' violates snake_case"

def test_partitioning(spark_session):
    silver_table = spark_session.table("silver.events")
    assert silver_table.partitionColumns == ['year', 'month', 'day']
```

## 7. Table Metadata Compliance

```python
def test_table_metadata(catalog):
    for table in catalog.listTables('silver'):
        meta = table.properties
        for required in ['owner', 'description', 'sla_latency_hours']:
            assert required in meta, f"{table.name}: missing {required}"
```

## Key Metrics

| Metric | Target | Tool |
|---|---|---|
| Test coverage | >80% of tables | pytest-cov |
| Data completeness | >99.5% | Great Expectations |
| Gold query SLA | <5s | Spark metrics |
| Freshness SLA | <24h latency | dbt freshness checks |
