const test = require('node:test');
const assert = require('node:assert/strict');

const { normalizeFamilyName } = require('../src/lib/familyNormalization');

test('normalizeFamilyName returns empty string for falsy input', () => {
  assert.equal(normalizeFamilyName(''), '');
  assert.equal(normalizeFamilyName(null), '');
  assert.equal(normalizeFamilyName(undefined), '');
});

test('normalizeFamilyName returns input unchanged when not a compute family', () => {
  assert.equal(normalizeFamilyName('someRandom'), 'someRandom');
  assert.equal(normalizeFamilyName('Memory Optimized'), 'Memory Optimized');
});

test('normalizeFamilyName normalizes standard compute family names', () => {
  assert.equal(normalizeFamilyName('Standard_DSv3 Family'), 'standardDSv3Family');
  assert.equal(normalizeFamilyName('standard_DSv3Family'), 'standardDSv3Family');
  assert.equal(normalizeFamilyName('standard DSv5 family'), 'standardDSv5Family');
  assert.equal(normalizeFamilyName('STANDARD_DSv3Family'), 'standardDSv3Family');
});

test('normalizeFamilyName normalizes basic compute family names', () => {
  // Dashes and underscores in the suffix are stripped by normalization
  assert.equal(normalizeFamilyName('Basic A0-A4 Family'), 'basicA0A4Family');
  assert.equal(normalizeFamilyName('basic_afamily'), 'basicAFamily');
});

test('normalizeFamilyName handles suffix-only family with no SKU part', () => {
  assert.equal(normalizeFamilyName('standard  family'), 'standardFamily');
  assert.equal(normalizeFamilyName('basic family'), 'basicFamily');
});

test('normalizeFamilyName trims whitespace', () => {
  assert.equal(normalizeFamilyName('  standardDSv3Family  '), 'standardDSv3Family');
});
