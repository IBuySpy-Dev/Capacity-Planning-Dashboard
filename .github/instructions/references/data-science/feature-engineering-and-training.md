# Feature Engineering & Model Training Reference

## Train/Test Split

- **Use a fixed random seed** for reproducible splits.
- **Stratified splits for classification:** `train_test_split(..., stratify=y)` maintains class distribution.
- **Time-series splits:** Use `TimeSeriesSplit()` or walk-forward validation; never shuffle temporal data.
- **No leakage:** Fit scalers/encoders on training data only, then apply to test data.

```python
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)  # Apply, don't refit
```

## Feature Engineering

- **Keep features interpretable:** Document what each feature represents.
- **One transformation per function:** Separate scaling, encoding, and domain logic.
- **Use `sklearn.pipeline.Pipeline`:** Chains transformations for reproducibility.
- **Document feature selection:** Record which features were selected and why.

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.compose import ColumnTransformer

numeric_transformer = Pipeline([("scaler", StandardScaler())])
preprocessor = ColumnTransformer([("num", numeric_transformer, numeric_features)])

full_pipeline = Pipeline([
    ("preprocessor", preprocessor),
    ("model", LogisticRegression())
])

full_pipeline.fit(X_train, y_train)
score = full_pipeline.score(X_test, y_test)
```

## Model Training & Evaluation

- **Log metrics:** Use pandas DataFrames or MLflow to log hyperparameters and scores.
- **Save best model:** Use joblib, pickle, or ONNX to `results/models/`.
- **Document baseline:** Record baseline performance (random guess, previous model).
- **Confusion matrix & ROC:** Always plot for classification tasks.

```python
from sklearn.metrics import classification_report, roc_auc_score
from sklearn.ensemble import RandomForestClassifier
import joblib, json

model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train_scaled, y_train)

y_pred = model.predict(X_test_scaled)
metrics = {
    "accuracy": model.score(X_test_scaled, y_test),
    "auc": roc_auc_score(y_test, model.predict_proba(X_test_scaled)[:, 1]),
    "classification_report": classification_report(y_test, y_pred, output_dict=True)
}

with open("results/metrics.json", "w") as f:
    json.dump(metrics, f, indent=2)

joblib.dump(model, "results/models/random_forest_v1.pkl")
```

## Cross-Validation

Use `cross_val_score()` or `KFold` for robust evaluation when the dataset is small.

```python
from sklearn.model_selection import cross_val_score, StratifiedKFold

cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(model, X, y, cv=cv, scoring="roc_auc")
print(f"AUC: {scores.mean():.3f} ± {scores.std():.3f}")
```
