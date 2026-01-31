import { $ } from 'bun';

export async function getSecret(name: string): Promise<string> {
  // Test mode returns mock data
  if (process.env.TEST_MODE === 'true') {
    const mockSecrets: Record<string, string> = {
      'openrouter-api-key': 'test-api-key-12345',
      'test-secret': 'test-value'
    };
    return mockSecrets[name] || '';
  }

  const result = await $`pass-cli item get ${name} --format json`.json();

  if (!result.data?.content?.itemData) {
    throw new Error(`Secret '${name}' not found in Proton Pass`);
  }

  // Handle different secret types
  return result.data.content.itemData.password
    || result.data.content.itemData.text
    || '';
}
