'use strict';

/**
 * Thin no-op-safe wrapper around Application Insights.
 *
 * If APPLICATIONINSIGHTS_CONNECTION_STRING is not set the module is a no-op so
 * callers do not need conditional guards. The SDK is already started in
 * server.js; here we only obtain the default client via `defaultClient`.
 */

function getClient() {
  if (!process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
    return null;
  }
  try {
    const ai = require('applicationinsights');
    return ai.defaultClient || null;
  } catch {
    return null;
  }
}

/**
 * Emit a named custom event with optional string properties and numeric measurements.
 *
 * @param {string} name  Event name (e.g. 'ingestion.completed')
 * @param {Record<string, string>} [properties]
 * @param {Record<string, number>} [measurements]
 */
function trackEvent(name, properties, measurements) {
  const client = getClient();
  if (!client) return;
  try {
    client.trackEvent({ name, properties, measurements });
  } catch {
    // Never let telemetry errors surface to callers.
  }
}

/**
 * Emit an exception to Application Insights.
 *
 * @param {Error|string} err
 * @param {Record<string, string>} [properties]
 */
function trackException(err, properties) {
  const client = getClient();
  if (!client) return;
  try {
    const exception = err instanceof Error ? err : new Error(String(err));
    client.trackException({ exception, properties });
  } catch {
    // Never let telemetry errors surface to callers.
  }
}

/**
 * Emit a named metric to Application Insights.
 *
 * @param {string} name
 * @param {number} value
 * @param {Record<string, string>} [properties]
 */
function trackMetric(name, value, properties) {
  const client = getClient();
  if (!client) return;
  try {
    client.trackMetric({ name, value, properties });
  } catch {
    // Never let telemetry errors surface to callers.
  }
}

module.exports = { trackEvent, trackException, trackMetric };
