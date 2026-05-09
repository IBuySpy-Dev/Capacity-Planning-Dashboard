const test = require('node:test');
const assert = require('node:assert/strict');

// ─── telemetry module ─────────────────────────────────────────────────────────
// Verifies the telemetry wrapper is a safe no-op when App Insights is not configured.

const telemetry = require('../src/services/telemetry');

test('telemetry.trackEvent is a no-op when APPLICATIONINSIGHTS_CONNECTION_STRING is not set', () => {
  const saved = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
  delete process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
  try {
    // Must not throw
    assert.doesNotThrow(() => telemetry.trackEvent('test.event', { key: 'value' }, { count: 1 }));
  } finally {
    if (saved !== undefined) process.env.APPLICATIONINSIGHTS_CONNECTION_STRING = saved;
  }
});

test('telemetry.trackException is a no-op when APPLICATIONINSIGHTS_CONNECTION_STRING is not set', () => {
  const saved = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
  delete process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
  try {
    assert.doesNotThrow(() => telemetry.trackException(new Error('boom'), { op: 'test' }));
    assert.doesNotThrow(() => telemetry.trackException('string error'));
  } finally {
    if (saved !== undefined) process.env.APPLICATIONINSIGHTS_CONNECTION_STRING = saved;
  }
});

test('telemetry.trackMetric is a no-op when APPLICATIONINSIGHTS_CONNECTION_STRING is not set', () => {
  const saved = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
  delete process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
  try {
    assert.doesNotThrow(() => telemetry.trackMetric('test.metric', 42, { region: 'eastus' }));
  } finally {
    if (saved !== undefined) process.env.APPLICATIONINSIGHTS_CONNECTION_STRING = saved;
  }
});
