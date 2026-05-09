# Medallion Architecture & DuckDB Reference

## Medallion Architecture (Lakehouse Pattern)

Organize data pipelines with bronze/silver/gold layers for clarity and quality.

| Layer | Purpose | Transformations |
|---|---|---|
| **Bronze** | Raw ingested data | Minimal (compression, partitioning) |
| **Silver** | Cleaned, validated data | Schema enforced, PII removed, deduplication |
| **Gold** | Aggregated, business-ready | Joined, denormalized for analytics/BI |

Each layer must document: quality checks applied, transformations, update frequency, owner, and SLA.

```
data/
├── bronze/
│   ├── raw_events_2024_01_01.parquet
│   └── raw_users_2024_01_01.parquet
├── silver/
│   ├── events_cleaned.parquet
│   └── users_deduplicated.parquet
└── gold/
    ├── daily_user_engagement.parquet
    └── user_cohorts.parquet
```

## DuckDB for Analytics and ETL

DuckDB is an in-process SQL database ideal for analytical workloads within notebooks.

- **Install:** `pip install duckdb`
- **Use cases:** SQL on pandas DataFrames, Parquet files, or CSV without data movement
- **Performance:** Vectorized execution, 10–100× faster than pandas for large aggregations
- **Integration:** Works with pandas, Parquet, Polars, and Apache Arrow

```python
import duckdb
import pandas as pd

# Query pandas DataFrame directly
df = pd.read_csv("data.csv")
result = duckdb.sql("SELECT * FROM df WHERE value > 100").df()

# Query Parquet files directly
result = duckdb.sql("SELECT COUNT(*) FROM read_parquet('data/silver/*.parquet')").df()
```

### Medallion Pipeline with DuckDB

```python
import duckdb

# Bronze → Silver
duckdb.sql("""
    CREATE TABLE silver.users AS
    SELECT user_id, CAST(created_at AS DATE) as created_date, email
    FROM read_parquet('data/bronze/users_raw_*.parquet')
    WHERE email IS NOT NULL
""")

# Silver → Gold
duckdb.sql("""
    CREATE TABLE gold.daily_users AS
    SELECT created_date, COUNT(DISTINCT user_id) as daily_signups
    FROM silver.users
    GROUP BY created_date
""")

result = duckdb.sql("SELECT * FROM gold.daily_users").df()
result.to_parquet("data/gold/daily_users.parquet")
```

### Performance Tips

- Use `read_parquet()` instead of loading to pandas for large files.
- Use `SELECT ... LIMIT` to preview data quickly.
- Use window functions (`ROW_NUMBER()`, `LAG()`) for advanced analytics.
- Push aggregations to SQL; only bring small results to pandas.

### Microsoft Fabric Integration

- Query Bronze/Silver/Gold layers without intermediate pandas copies.
- Use DuckDB for local development; Spark for production scale-out.
- Load Fabric lakehouse tables via Spark integration.

## Data Validation

Validate data quality before processing to catch issues early.

```python
import pandera as pa

schema = pa.DataFrameSchema({
    "user_id": pa.Column(pa.Int64, checks=pa.Check.greater_than(0)),
    "age": pa.Column(pa.Int32, checks=[
        pa.Check.greater_than_or_equal_to(0),
        pa.Check.less_than_or_equal_to(150)
    ]),
    "email": pa.Column(pa.String, nullable=False)
})

validated_df = schema.validate(df)
```
