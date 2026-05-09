# Notebook Conventions Reference

## Project Structure

```
project/
├── data/
│   ├── raw/                 # Unmodified source data
│   ├── bronze/              # Raw ingested data (medallion)
│   ├── silver/              # Cleaned, deduplicated data
│   └── gold/                # Aggregated, business-ready data
├── notebooks/
│   ├── 01_exploratory_analysis.ipynb
│   ├── 02_data_preparation.ipynb
│   └── 03_model_training.ipynb
├── src/
│   ├── __init__.py
│   ├── data.py              # Data loading, transformation
│   ├── features.py          # Feature engineering
│   └── models.py            # Model training, evaluation
├── tests/
│   ├── test_data.py
│   └── test_features.py
├── results/
│   ├── models/              # Trained model artifacts
│   ├── figures/             # Generated plots
│   └── metrics.json         # Model performance metrics
├── requirements.txt         # Python dependencies (pinned)
└── README.md                # Project overview
```

## Notebook Idempotency

Notebooks must execute top-to-bottom without errors:

- **No hidden state:** Avoid relying on cells run out-of-order.
- **Restart kernel before commit:** Use Kernel → Restart & Run All to verify.
- **Initialize variables at the top:** Set random seeds, file paths, and configuration in the first cell.

```python
# Configuration cell — always first
import numpy as np
import pandas as pd
from pathlib import Path

np.random.seed(42)
DATA_DIR = Path.cwd() / "data"
RAW_DATA = DATA_DIR / "raw" / "dataset.csv"
PROCESSED_DATA = DATA_DIR / "silver" / "processed.parquet"
```

## Cell Output Hygiene

- **Clear outputs before committing:** Use Kernel → Restart & Clear Output.
- **Use nbstripout for automation:** `pip install nbstripout && nbstripout --install` adds a git hook.
- **Large visualizations:** Save to disk instead of embedding in notebook cells.
- **Data inspection:** Use `.head()`, `.info()`, `.describe()` (fine to keep).

## Reproducibility

- **Pin all dependencies** with exact versions in `requirements.txt` or `environment.yml`.
- **Document data sources:** Include URLs, download dates, and checksums.
- **Fix random seeds** at initialization (`np.random.seed()`, `torch.manual_seed()`).
- **Version control scripts, not outputs:** Commit `.py` files and notebooks, not model files or large CSVs.

## Platform-Specific Notes

### Microsoft Fabric Spark

- Use PySpark for 10GB+; pandas for <1GB per partition.
- Partition large tables by date or category.
- Use Parquet (not CSV) for Spark table I/O.
- Keep notebooks, lakehouse tables, and models organized by domain.

### Jupyter Best Practices

- **Notebook naming:** Use numeric prefixes (`01_`, `02_`) to indicate execution order.
- **Cell length:** Keep cells <50 lines; split complex logic into `src/` functions.
- **Markdown documentation:** Use markdown cells to document each section's purpose.

## Testing Notebooks and Pipelines

- **Unit tests:** Test `src/` modules via `pytest`.
- **Integration tests:** Use `nbval` or `papermill` to execute notebooks end-to-end.
- **Data tests:** Validate output datasets with `pandera`.

```bash
pip install nbval
pytest --nbval notebooks/
```
