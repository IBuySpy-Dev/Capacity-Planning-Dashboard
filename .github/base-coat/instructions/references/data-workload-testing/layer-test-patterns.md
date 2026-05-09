# Medallion Layer Test Patterns Reference

## Bronze Layer Tests

Bronze is append-only raw data. Validate immutability and lineage tracking.

```python
def test_bronze_immutability(spark_session):
    """Bronze layer should be append-only — no updates/deletes."""
    df = spark_session.table("bronze.raw_events")
    timestamps = df.select('_loaded_at').rdd.flatMap(lambda x: x).collect()
    assert timestamps == sorted(timestamps), "Bronze: timestamps not monotonic"

def test_bronze_lineage_tracking(spark_session):
    """Bronze must track source lineage."""
    df = spark_session.table("bronze.raw_events")
    required = ['_source_system', '_loaded_at', '_file_path']
    for col in required:
        assert col in df.columns, f"Bronze missing lineage column: {col}"
```

## Silver Layer Tests

Silver is cleaned and deduplicated. Validate dbt documentation and schema.

```python
def test_silver_dbt_documentation(catalog):
    """Silver tables must have dbt documentation."""
    for table in catalog.listTables('silver'):
        manifest = read_dbt_manifest('target/manifest.json')
        node = manifest['nodes'].get(f'model.analytics.{table.name}')
        assert node is not None, f"Missing dbt doc for {table.name}"
        assert node.get('description'), f"Missing description for {table.name}"
```

## Gold Layer Tests

Gold is aggregated and analytics-ready. Validate correctness and SLA.

```python
def test_gold_query_performance(spark_session):
    """Gold queries must meet <5s SLA."""
    import time
    start = time.time()
    spark_session.sql("""
        SELECT date(event_date) as day, COUNT(*) as cnt
        FROM gold.daily_events
        WHERE event_date >= DATE_SUB(CURRENT_DATE, 90)
        GROUP BY 1
    """).collect()
    elapsed = time.time() - start
    assert elapsed < 5, f"Gold SLA violated: {elapsed:.2f}s (expected <5s)"
```

## Integration Tests (Cross-Layer)

```python
def test_bronze_to_silver_propagation(spark_session):
    """All bronze records should propagate to silver (allow <5% dedup loss)."""
    bronze_count = spark_session.table("bronze.events").count()
    silver_count = spark_session.table("silver.events").count()
    assert silver_count >= bronze_count * 0.95, \
        f"Silver lost >5% of bronze records ({silver_count} vs {bronze_count})"

def test_silver_to_gold_aggregation(spark_session):
    """Gold aggregates must match silver source truth."""
    expected = spark_session.sql("""
        SELECT DATE(event_timestamp) as day, COUNT(*) as count
        FROM silver.events GROUP BY 1
    """)
    actual = spark_session.table("gold.daily_event_counts")
    diff = expected.except_all(actual)
    assert diff.count() == 0, f"Found {diff.count()} mismatched aggregates"
```

## Test Organization

```
tests/
├── data/
│   ├── bronze/          # test_bronze_*.py
│   ├── silver/          # test_silver_*.py
│   ├── gold/            # test_gold_*.py
│   ├── integration/     # test_end_to_end.py
│   └── conftest.py      # Shared fixtures
└── sql/
    ├── test_referential_integrity.sql
    └── test_data_quality.sql
```

## Pytest Fixtures

```python
# tests/data/conftest.py
import pytest
from pyspark.sql import SparkSession

@pytest.fixture(scope="session")
def spark_session():
    return SparkSession.builder \
        .appName("data-tests") \
        .config("spark.sql.shuffle.partitions", "1") \
        .getOrCreate()

@pytest.fixture
def sample_bronze_data(spark_session):
    return spark_session.sql("SELECT * FROM bronze.events LIMIT 1000")
```

## Running Tests

```bash
# All data tests
pytest tests/data/ -v

# Specific layer
pytest tests/data/silver/ -v

# With coverage
pytest tests/data/ --cov=dbt --cov-report=html

# SQL linting
sqlfluff lint dbt/models/silver/ --dialect ansi
dbt test --select tag:critical
```

## CI/CD Integration

```yaml
# .github/workflows/data-quality.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run data quality tests
        run: pytest tests/data/ -v --junit-xml=results.xml
      - name: dbt test
        run: dbt test --profiles-dir profiles/ --select tag:critical
      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: results.xml
```
