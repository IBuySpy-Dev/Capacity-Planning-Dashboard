# E2E Testing — Cypress Patterns

## Setup

```bash
npm install -D cypress
npx cypress open  # generates config
```

### cypress.config.js

```javascript
const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.js',
    defaultCommandTimeout: 5000,
    requestTimeout: 5000,
    responseTimeout: 10000,
    viewportWidth: 1280,
    viewportHeight: 720,
    screenshotOnRunFailure: true,
    video: true,
  },
});
```

## Test Patterns

### Basic Test

```javascript
describe('Checkout flow', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.login('test@example.com', 'password');
  });

  it('should complete purchase', () => {
    cy.get('[data-testid="search"]').type('Blue Widget');
    cy.get('button:contains("Search")').click();
    cy.contains('Blue Widget').should('be.visible');

    cy.get('[data-testid="add-to-cart"]').click();
    cy.get('[data-testid="cart-count"]').should('contain', '1');

    cy.visit('/checkout');
    cy.get('[name="address"]').type('123 Main St');
    cy.get('button:contains("Continue")').click();
    cy.contains('Order Confirmed').should('be.visible');
  });
});
```

### Custom Commands

```javascript
// cypress/support/commands.js
Cypress.Commands.add('login', (email, password) => {
  cy.visit('/login');
  cy.get('[name="email"]').type(email);
  cy.get('[name="password"]').type(password);
  cy.get('button:contains("Login")').click();
  cy.url().should('not.include', '/login');
});

Cypress.Commands.add('logout', () => {
  cy.get('[data-testid="logout-btn"]').click();
  cy.url().should('include', '/login');
});
```

### API Mocking

```javascript
cy.intercept('GET', '/api/users/**', { fixture: 'users.json' }).as('getUsers');
cy.visit('/users');
cy.wait('@getUsers');
cy.contains('Alice').should('be.visible');
```

## Cypress vs Playwright Trade-offs

| Aspect | Cypress | Playwright |
|---|---|---|
| Debug experience | Time-travel debugger | Trace viewer |
| Parallel CI | Cypress Cloud (paid) | Native (free) |
| Browser support | Chrome, Firefox, Electron | + WebKit (Safari) |
| Best for | Fast iteration in JS teams | Cross-browser, multi-language |
