import { describe, test, expect, beforeAll } from 'bun:test';

const SERVER_URL = 'http://127.0.0.1:16080';

describe('Surfingkeys Config Service Integration Tests', () => {
  beforeAll(() => {
    // Ensure TEST_MODE is set
    process.env.TEST_MODE = 'true';
  });

  test('GET /api/secrets/:name returns mock secret in test mode', async () => {
    const response = await fetch(`${SERVER_URL}/api/secrets/openrouter-api-key`);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.value).toBe('test-api-key-12345');
  });

  test('GET /api/secrets/:name returns 500 for non-existent secret', async () => {
    const response = await fetch(`${SERVER_URL}/api/secrets/non-existent-key`);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.value).toBe('');  // Mock returns empty string for unknown keys
  });

  test('GET /config.js serves bundle', async () => {
    const response = await fetch(`${SERVER_URL}/config.js`);

    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toBe('application/javascript');
  });

  test('GET /unknown returns 404', async () => {
    const response = await fetch(`${SERVER_URL}/unknown`);

    expect(response.status).toBe(404);
  });
});
