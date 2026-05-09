# Mutation Testing Tools & CI Reference

## Python: Mutmut

```bash
pip install mutmut pytest
mutmut run --paths-to-mutate src/
mutmut results
mutmut html          # HTML report
```

**setup.cfg:**

```ini
[mutmut]
paths_to_mutate = src/
tests_dir = tests/
mutants_per_file = 8
```

## JavaScript/TypeScript: Stryker

```bash
npm install -D @stryker-mutator/core @stryker-mutator/jest-runner
npx stryker init
npx stryker run
```

**stryker.conf.json:**

```json
{
  "testRunner": "jest",
  "mutate": ["src/**/*.ts", "!src/**/*.spec.ts"],
  "reporters": ["html", "json"],
  "concurrency": 4,
  "mutationThreshold": { "high": 80, "medium": 70, "low": 60 }
}
```

## Java: PIT (Maven)

```xml
<plugin>
  <groupId>org.pitest</groupId>
  <artifactId>pitest-maven</artifactId>
  <version>1.14.0</version>
  <configuration>
    <targetClasses><param>com.example.*</param></targetClasses>
    <targetTests><param>com.example.*Test</param></targetTests>
  </configuration>
</plugin>
```

```bash
mvn org.pitest:pitest-maven:mutationCoverage
```

## CI/CD Integration

### Python (mutmut + GitHub Actions)

```yaml
jobs:
  mutmut:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with: { python-version: "3.11" }
      - run: pip install mutmut pytest
      - run: mutmut run --paths-to-mutate src/
      - run: |
          SCORE=$(mutmut results --print-coverage | grep -oP '\d+(?=%)')
          if [ "$SCORE" -lt 80 ]; then echo "Mutation score too low: $SCORE%"; exit 1; fi
```

### JavaScript (Stryker + GitHub Actions)

```yaml
jobs:
  stryker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "18" }
      - run: npm ci
      - run: npm run test
      - run: npx stryker run
      - uses: actions/upload-artifact@v4
        with: { name: stryker-report, path: reports/ }
```

## Mutation Score Interpretation

| Score | Verdict | Action |
|---|---|---|
| >85% | ✅ Production-ready | Monitor on CI |
| 70–85% | ⚠️ Acceptable | Plan improvements in next sprint |
| <70% | ❌ Remediation required | Halt features, fix critical gaps first |

## Improvement Strategy

**Phase 1 — Baseline (1 sprint):** Run mutation testing, record score, fix top 20 survived mutations → target 70–75%.

**Phase 2 — Close Gaps (2–3 sprints):** Group survived mutations by category (boundary/error/validation), fix batch by batch → target 80–85%.

**Phase 3 — Hardening (ongoing):** Monitor on every commit, fail CI if score drops below threshold, dedicate 5–10% of sprint capacity → maintain 85%+.
