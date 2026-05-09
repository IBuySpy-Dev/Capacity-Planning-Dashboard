# E2E Testing & Integration Orchestration

## E2E Test with Selenium

```python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait

def test_complete_checkout():
    driver = webdriver.Chrome()
    try:
        driver.get("https://shop.example.com")
        driver.find_element(By.ID, "search").send_keys("laptop")
        driver.find_element(By.ID, "search-btn").click()

        product = WebDriverWait(driver, 10).until(
            lambda d: d.find_element(By.CLASS_NAME, "product-card")
        )
        product.find_element(By.CLASS_NAME, "add-to-cart").click()
        driver.find_element(By.ID, "checkout-btn").click()

        driver.find_element(By.NAME, "address").send_keys("123 Main St")
        driver.find_element(By.NAME, "city").send_keys("Portland")
        driver.find_element(By.NAME, "zip").send_keys("97201")

        driver.switch_to.frame("payment-iframe")
        driver.find_element(By.NAME, "cardnumber").send_keys("4111111111111111")
        driver.switch_to.default_content()
        driver.find_element(By.ID, "submit-order").click()

        confirmation = WebDriverWait(driver, 10).until(
            lambda d: d.find_element(By.CLASS_NAME, "confirmation-message")
        )
        assert "Order confirmed" in confirmation.text
    finally:
        driver.quit()
```

## Integration Test Orchestration (Docker Compose)

```yaml
# docker-compose.yml
version: "3.9"
services:
  order-service:
    image: order-service:test
    environment:
      PAYMENT_URL: http://payment-service:8080

  payment-service:
    image: payment-service:test
    environment:
      ORDER_URL: http://order-service:8080

  inventory-service:
    image: inventory-service:test

  test-runner:
    image: test-runner:latest
    depends_on: [order-service, payment-service, inventory-service]
    command: pytest /tests/ -v --junit-xml=/results/report.xml
```

## Mutation Testing

```python
def calculate_discount(total, is_member):
    if is_member and total > 100:
        return total * 0.9
    return total

# Mutations that should fail: change '>' to '>=', 'and' to 'or', 0.9 to 0.8
# Target: > 85% mutation score
```

- [Mutation Testing Guidelines](https://en.wikipedia.org/wiki/Mutation_testing)

## Contract Test Report Template

```yaml
Contract Verification Report:
  Summary:
    Total Contracts: 12
    Verified: 11 ✅
    Failed: 1 ⚠️
  Failures:
    - Contract: "Payment-Order Integration"
      Reason: "Missing 'transaction_id' field in response"
      Impact: "CRITICAL: Payment capture will fail"
      Priority: P1
  Mutation Test Results:
    Order Service: 92% ✅
    Payment Service: 78% ❌ (threshold: 85%)
  Deployment Gate: 🔴 BLOCKED
```
