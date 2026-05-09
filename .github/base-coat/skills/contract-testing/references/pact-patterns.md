# Pact Contract Testing Patterns

## Consumer Contract Definition

```python
from pact import Consumer, Provider

pact = Consumer("Payment Service").has_pact_with(Provider("Order Service"))

(pact
 .upon_receiving("a request for order details")
 .with_request("GET", "/orders/12345")
 .will_respond_with(200, body={
     "id": "12345",
     "total_amount": 99.99,
     "status": "pending_capture",
     "items": [{"product_id": "abc", "quantity": 1, "price": 99.99}]
 }))

pact.verify()
pact.write_to_file()
```

## Provider Contract Verification

```python
from pact_provider import Verifier

verifier = Verifier(
    provider="Order Service",
    provider_base_url="http://localhost:8080"
)

result = verifier.verify_pacts(
    pact_urls=["pacts/Payment Service-Order Service.json"],
    provider_states_setup_url="http://localhost:8080/provider-states"
)

if not result:
    raise Exception("Contract verification failed!")
```

## Provider States Setup

```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/provider-states", methods=["POST"])
def set_provider_state():
    state = request.json.get("state")

    if state == "order 12345 exists":
        db.execute("INSERT INTO orders VALUES (12345, 99.99, 'pending_capture')")
        return jsonify({"ok": True}), 200

    elif state == "order 12345 captured":
        db.execute("UPDATE orders SET status='captured' WHERE id=12345")
        return jsonify({"ok": True}), 200

    return jsonify({"error": "Unknown state"}), 400
```

## References

- [Pact Specification](https://pact.foundation/)
- [Consumer-Driven Contract Testing](https://martinfowler.com/articles/consumerDrivenContracts.html)
