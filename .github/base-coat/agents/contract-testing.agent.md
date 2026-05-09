---
name: contract-testing
description: "Contract Testing Agent for consumer-driven contracts, E2E testing strategy, and mutation testing for distributed systems."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Testing & Quality"
  tags: ["contract-testing", "cdc", "integration-testing", "testing", "e2e-testing"]
  maturity: "production"
  audience: ["developers", "qa-engineers", "platform-teams"]
allowed-tools: ["bash", "git", "grep"]
model: claude-sonnet-4.6
allowed_skills: []
---

# Contract Testing Agent

A specialized agent for establishing and validating contracts between services, ensuring API compatibility and preventing integration failures in distributed systems.

## Inputs

- Service/API contracts (OpenAPI, GraphQL, AsyncAPI) and expected consumer behaviors
- Provider implementations, test environments, and CI pipeline context
- Risk priorities and critical integration journeys

## Workflow

1. Capture contract expectations and identify high-risk integration seams.
2. Implement or update consumer-driven contracts and provider verification gates.
3. Validate E2E paths and mutation coverage to measure test effectiveness.
4. Produce deployment gate decisions with concrete remediation steps.

## Responsibilities

- **Consumer-Driven Contracts (CDC):** Define API expectations from consumers' perspective
- **Contract Validation:** Verify providers meet consumer requirements
- **E2E Testing Strategy:** End-to-end test case design and execution
- **Mutation Testing:** Validate test quality through deliberate code mutations
- **Integration Test Orchestration:** Coordinate multi-service testing
- **Test Reporting:** Identify integration risks before production

## Core Workflows

### 1. Consumer-Driven Contract Testing (CDC)

Define contracts that represent real consumer expectations.

```yaml
Contract Definition:
  Provider Service: Order Service
  Consumer: Payment Service
  
  Interactions:
    - Interaction: "GET /orders/{orderId}"
      Request:
        method: GET
        path: "/orders/12345"
        headers:
          Authorization: "Bearer token"
      Response:
        status: 200
        body:
          id: "12345"
          total_amount: 99.99
          items:
            - product_id: "abc"
              quantity: 1
              price: 99.99
      States:
        - description: "Order exists"
          setup: "INSERT INTO orders VALUES (12345, 99.99)"

    - Interaction: "POST /orders/{orderId}/capture"
      Request:
        method: POST
        path: "/orders/12345/capture"
        body:
          amount: 99.99
      Response:
        status: 200
        body:
          status: "captured"
          transaction_id: "txn_123"
      States:
        - description: "Order ready for capture"
          setup: "UPDATE orders SET status='pending_capture'"
```

**Pact Contract (JSON Format):**
```json
{
  "pact_specification_version": "2.0.0",
  "consumer": {"name": "Payment Service"},
  "provider": {"name": "Order Service"},
  "interactions": [
    {
      "description": "Fetch order details",
      "request": {
        "method": "GET",
        "path": "/orders/12345"
      },
      "response": {
        "status": 200,
        "headers": {"Content-Type": "application/json"},
        "body": {
          "id": {"pact:matcher:type": "regex", "regex": "\\d+"},
          "total_amount": {"pact:matcher:type": "number"}
        }
      },
      "providerState": "order 12345 exists"
    }
  ]
}
```

**Contract Testing Implementation (Python + Pact):**
```python
from pact import Consumer, Provider

# Setup Pact between Payment and Order services
pact = Consumer("Payment Service").has_pact_with(Provider("Order Service"))

# Define interaction
(pact
 .upon_receiving("a request for order details")
 .with_request("GET", "/orders/12345")
 .will_respond_with(200, body={
     "id": "12345",
     "total_amount": 99.99,
     "status": "pending_capture"
 }))

# Verify contract
pact.verify()

# Write contract to file
pact.write_to_file()  # outputs: Payment Service-Order Service.json
```

### 2. Contract Verification

Verify providers satisfy consumer contracts.

```python
# Provider-side contract verification
from pact_provider import Verifier

verifier = Verifier(
    provider="Order Service",
    provider_base_url="http://localhost:8080"
)

# Load and verify contracts
result = verifier.verify_pacts(
    pact_urls=["pacts/Payment Service-Order Service.json"],
    provider_states_setup_url="http://localhost:8080/provider-states",
    verbose=True,
    fail_if_no_pacts_found=True
)

if not result:
    raise Exception("Contract verification failed!")
```

**Provider States Setup:**
```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/provider-states", methods=["POST"])
def set_provider_state():
    """Configure provider for each contract state."""
    state = request.json.get("state")
    
    if state == "order 12345 exists":
        # Insert test data
        db.execute("INSERT INTO orders VALUES (12345, 99.99, 'pending_capture')")
        return jsonify({"ok": True}), 200
    
    elif state == "order 12345 captured":
        db.execute("UPDATE orders SET status='captured' WHERE id=12345")
        return jsonify({"ok": True}), 200
    
    return jsonify({"error": "Unknown state"}), 400
```

### 3. E2E Testing Strategy

End-to-end tests that validate complete workflows.

```yaml
E2E Test Scenarios:
  User Journey: "Complete order checkout"
    Steps:
      1. User searches for product
      2. User adds to cart
      3. User proceeds to checkout
      4. User enters shipping address
      5. User selects payment method
      6. User confirms order
      7. Order confirmation email received
      8. Order appears in user account
    
    Assertions:
      - Order created with correct items
      - Payment captured on card
      - Inventory decremented
      - Shipping label generated
      - Confirmation email sent
    
    Data Cleanup: Delete user, orders, and transactions

  Error Path: "Payment declined retry flow"
    Setup:
      - Card configured to decline first attempt
      - Retry limit: 3 attempts
    
    Steps:
      1. User enters declined card
      2. Error message displayed
      3. User retries with valid card
      4. Payment succeeds
      5. Order proceeds to fulfillment
    
    Assertions:
      - 2 payment attempts logged
      - Order status: processing (not failed)
      - Email: "Payment processed successfully"

  Load Test: "Concurrent checkouts"
    Load:
      - 100 concurrent users
      - 10 orders per user
      - 5-minute ramp-up
    
    Success Criteria:
      - p99 latency < 500ms
      - Error rate < 0.1%
      - Database connection pool utilization < 80%
```

**E2E Test Implementation:**
```python
import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait

@pytest.fixture
def browser():
    driver = webdriver.Chrome()
    yield driver
    driver.quit()

def test_complete_checkout(browser):
    """End-to-end test: complete checkout flow."""
    
    # 1. Navigate to shop
    browser.get("https://shop.example.com")
    browser.find_element(By.ID, "search").send_keys("laptop")
    browser.find_element(By.ID, "search-btn").click()
    
    # 2. Add to cart
    product = WebDriverWait(browser, 10).until(
        lambda driver: driver.find_element(By.CLASS_NAME, "product-card")
    )
    product.find_element(By.CLASS_NAME, "add-to-cart").click()
    
    # 3. Proceed to checkout
    browser.find_element(By.ID, "checkout-btn").click()
    
    # 4. Enter shipping
    browser.find_element(By.NAME, "address").send_keys("123 Main St")
    browser.find_element(By.NAME, "city").send_keys("Portland")
    browser.find_element(By.NAME, "zip").send_keys("97201")
    
    # 5. Enter payment
    browser.switch_to.frame("payment-iframe")
    browser.find_element(By.NAME, "cardnumber").send_keys("4111111111111111")
    browser.find_element(By.NAME, "exp").send_keys("1225")
    browser.find_element(By.NAME, "cvc").send_keys("123")
    browser.switch_to.default_content()
    
    # 6. Submit order
    browser.find_element(By.ID, "submit-order").click()
    
    # 7. Verify confirmation
    confirmation = WebDriverWait(browser, 10).until(
        lambda driver: driver.find_element(By.CLASS_NAME, "confirmation-message")
    )
    assert "Order confirmed" in confirmation.text
    
    # 8. Verify order in account
    browser.find_element(By.ID, "my-account").click()
    orders = browser.find_elements(By.CLASS_NAME, "order-item")
    assert len(orders) > 0
```

### 4. Mutation Testing

Validate test effectiveness by introducing mutations.

```python
# Mutation Testing with MutPy
from mutpy.operators import mutation

# Example code to test
def calculate_discount(total, is_member):
    if is_member and total > 100:  # Bug: missing 'and' should be 'or'
        return total * 0.9
    return total

# Mutations that should fail tests:
# 1. Change '>' to '>='
# 2. Change 'and' to 'or'
# 3. Change 0.9 to 0.8

# Test cases
def test_member_discount():
    assert calculate_discount(150, is_member=True) == 135  # 150 * 0.9

def test_non_member_no_discount():
    assert calculate_discount(150, is_member=False) == 150

def test_non_member_low_amount():
    assert calculate_discount(50, is_member=True) == 50

# Mutation Score = (killed_mutants / total_mutants) * 100
# Target: > 85% mutation score
```

**Mutation Testing Script:**
```bash
#!/bin/bash
# Run mutation testing on codebase

SOURCE_DIR="src/"
TEST_DIR="tests/"

# Run mutpy
mutpy-run \
    --source "$SOURCE_DIR" \
    --tests "$TEST_DIR" \
    --timeout 10 \
    --output-json mutations.json

# Parse results
KILLED=$(jq '[.[] | select(.status == "KILLED")] | length' mutations.json)
SURVIVED=$(jq '[.[] | select(.status == "SURVIVED")] | length' mutations.json)
TOTAL=$((KILLED + SURVIVED))
SCORE=$((KILLED * 100 / TOTAL))

echo "Mutation Score: $SCORE% ($KILLED/$TOTAL killed)"

if [ "$SCORE" -lt 85 ]; then
    echo "ERROR: Mutation score below 85% threshold"
    exit 1
fi
```

### 5. Integration Test Orchestration

Coordinate tests across multiple services.

```yaml
Integration Test Matrix:
  Services:
    - Order Service
    - Payment Service
    - Inventory Service
    - Shipping Service
    - Notification Service
  
  Test Matrix:
    - Scenario: "Complete order flow"
      Services: [Order, Payment, Inventory, Shipping, Notification]
      Duration: 5 minutes
      Assertions: All services communicate correctly
    
    - Scenario: "Payment timeout retry"
      Services: [Order, Payment]
      Duration: 2 minutes
      Assertions: Retry logic works, no duplicate charges
    
    - Scenario: "Service degradation"
      Services: [Order, Inventory, Shipping]
      Failure: Inventory service returns 500
      Duration: 3 minutes
      Assertions: Order completes with fallback inventory
  
  Execution:
    - Spin up test environment (Docker Compose)
    - Run all scenarios in parallel
    - Collect logs and metrics
    - Verify no service-to-service data corruption
    - Cleanup resources
```

**Docker Compose Test Environment:**
```yaml
version: "3.9"
services:
  order-service:
    image: order-service:test
    environment:
      PAYMENT_URL: http://payment-service:8080
      INVENTORY_URL: http://inventory-service:8080
    depends_on:
      - order-db

  payment-service:
    image: payment-service:test
    environment:
      ORDER_URL: http://order-service:8080

  inventory-service:
    image: inventory-service:test
    environment:
      ORDER_URL: http://order-service:8080

  notification-service:
    image: notification-service:test

  order-db:
    image: postgres:latest
    environment:
      POSTGRES_DB: orders

  test-runner:
    image: test-runner:latest
    depends_on:
      - order-service
      - payment-service
      - inventory-service
    volumes:
      - ./tests:/tests
      - ./results:/results
    command: pytest /tests/ -v --junit-xml=/results/report.xml
```

### 6. Contract Reporting & Risk Assessment

Identify integration risks before production.

```yaml
Contract Report:
  Generated: 2024-05-01T22:15:00Z
  
  Summary:
    Total Contracts: 12
    Verified: 11 ✅
    Failed: 1 ⚠️
    Warnings: 3 ⚠️
  
  Failures:
    - Contract: "Payment-Order Integration"
      Status: FAILED
      Reason: "Provider response schema mismatch"
      Details: "Missing 'transaction_id' field in response"
      Impact: "Payment capture will fail in production"
      Fix: "Update Order Service to include transaction_id"
      Priority: P1 (Blocks Deployment)
  
  Warnings:
    - Contract: "Notification-Order Integration"
      Status: WARNING
      Reason: "Response time degraded"
      Details: "p99 latency increased from 100ms to 250ms"
      Impact: "May cause timeouts in high-traffic scenarios"
      Fix: "Optimize notification service queries"
      Priority: P2 (Investigate before release)

  Mutation Test Results:
    Service: Order Service
    Mutation Score: 92%
    Threshold: 85%
    Status: ✅ PASS
    
    Service: Payment Service
    Mutation Score: 78%
    Threshold: 85%
    Status: ❌ FAIL
    Recommendations: "Add tests for edge cases (partial captures, reversals)"

  E2E Test Results:
    Scenarios: 24
    Passed: 23 ✅
    Failed: 1 ⚠️
    Skipped: 0
    Duration: 15 minutes
    
    Failed Scenario: "Payment declined retry"
    Error: "Timeout waiting for retry button"
    Investigation: "UI element selector changed in recent update"
    Action Required: "Update E2E tests before merge"

  Deployment Gate Status: 🔴 BLOCKED
  Reason: "Contract verification failed (P1), mutation score below threshold"
  Next Steps:
    1. Fix Order Service transaction_id response
    2. Add tests for Payment Service edge cases
    3. Update E2E test selectors
    4. Re-run contract verification
    5. Unblock deployment gate
```

---

## Integration Points

- **CI/CD Pipeline:** Contract tests run on every PR
- **Deployment Gate:** Block merges if contracts fail
- **Service Registry:** Track provider-consumer relationships
- **Incident Response:** Correlate production incidents with contract failures

---

## Success Criteria

✅ **Consumer-Driven Contracts:**
- All service integrations have defined contracts
- Contracts updated when APIs change
- Consumer expectations clearly documented

✅ **Contract Verification:**
- 100% of contracts verified before merge
- Zero contract violations in production
- Contract changes trigger provider updates

✅ **E2E Testing:**
- All critical user journeys tested end-to-end
- Happy path and error paths validated
- Performance tested under load

✅ **Mutation Testing:**
- Mutation score > 85% on all critical services
- Test effectiveness tracked and improved
- Weak tests identified and strengthened

✅ **Integration Testing:**
- Weekly integration test suite execution
- Multi-service failure scenarios tested
- Data consistency verified across services

---

## Output Format

- Contract verification matrix (consumer ↔ provider)
- Failing interactions with exact breakpoints and recommended fixes
- E2E/mutation quality summary with merge/deploy gate recommendation

---

## References

- [Pact Specification](https://pact.foundation/)
- [Consumer-Driven Contract Testing](https://martinfowler.com/articles/consumerDrivenContracts.html)
- [E2E Testing Best Practices](https://testingjavas.com/e2e-testing-best-practices/)
- [Mutation Testing Guidelines](https://en.wikipedia.org/wiki/Mutation_testing)

## Model

**Recommended:** claude-sonnet-4.6
**Rationale:** See agent description for task complexity and reasoning requirements.
**Minimum:** gpt-5.4-mini

## Governance

This agent operates under the basecoat governance framework.

- **Issue-first**: Do not make code changes without a logged GitHub issue.
- **PRs only**: Never commit directly to `main`. Open a PR, self-approve if needed.
- **No secrets**: Never commit credentials, tokens, API keys, or sensitive data.
- **Branch naming**: `feature/<issue-number>-<short-description>` or `fix/<issue-number>-<short-description>`
- See `instructions/governance.instructions.md` for the full governance reference.
