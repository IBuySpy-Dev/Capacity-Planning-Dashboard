# Survival Patterns & Fixes Reference

## How Mutations Are Generated

The mutation tester introduces deliberate bugs to verify your tests catch them:

```python
# Original
def calculate_discount(price, customer_type):
    if customer_type == 'premium':
        return price * 0.9  # 10% discount
    return price

# Mutation 1: operator changed (* → +)
    return price + 0.9   # BUG: adds instead of multiplies

# Mutation 2: condition deleted
    # if customer_type == 'premium':
    return price * 0.9   # BUG: always applies discount
```

If tests still pass after either mutation → **survived** (test quality gap).
If tests fail → **killed** (good quality).

---

## Pattern 1 — Boundary Conditions

```python
# Code
def is_valid_age(age):
    return age >= 18

# Mutation: >= becomes >
    return age > 18  # BUG: age 18 is rejected

# Fix — test the exact boundary
def test_is_valid_age_boundary():
    assert is_valid_age(17) == False
    assert is_valid_age(18) == True   # catches >= vs > mutation
    assert is_valid_age(19) == True
```

## Pattern 2 — Conditional Deletion

```python
# Code
def process_order(order, user):
    if not user.is_authenticated:
        raise Unauthorized()
    ...

# Mutation: entire condition deleted — no auth check at all

# Fix — explicitly test the guard
def test_unauthenticated_blocked():
    with pytest.raises(Unauthorized):
        process_order(Order(total=100), User(authenticated=False))
```

## Pattern 3 — Operator Mutations

```python
# Code
def calculate_total(subtotal, tax_rate):
    return subtotal * (1 + tax_rate)

# Mutation: * becomes /
    return subtotal / (1 + tax_rate)  # BUG

# Fix — assert on an output that differs between operators
def test_tax_calculation():
    # 100 * 1.1 = 110; 100 / 1.1 ≈ 90.9
    assert calculate_total(100, 0.1) == 110.0
```

## Pattern 4 — Return Value Mutations

```python
# Code
def validate_email(email):
    if '@' not in email:
        return False
    ...

# Mutation: return False → return True

# Fix — test invalid input explicitly
def test_validate_email_invalid():
    assert validate_email('invalid') == False
    assert validate_email('no-at-sign.com') == False
```

---

## Common Mistakes

❌ **High coverage, low mutation score** — Tests execute code but never assert on results. Fix: assert on return values and side effects.

❌ **Fixing random mutations** — Fixing one-off survivors without understanding categories. Fix: group survived mutations by type, fix systematically.

❌ **Treating mutation score as absolute** — 90% score doesn't guarantee production-readiness; non-testable mutations (logging, timeouts) inflate the denominator. Use score as a trend indicator, not a gate.

---

## Test Quality Checklist

- [ ] Line coverage ≥ 80%
- [ ] Mutation score ≥ 85%
- [ ] All error paths tested (exception handling, null checks)
- [ ] Boundary conditions tested (off-by-one, edge values)
- [ ] Invalid inputs rejected (validation tests)
- [ ] Concurrent / async operations handled
- [ ] Performance regression tests for critical paths
- [ ] Integration tests for all dependencies
