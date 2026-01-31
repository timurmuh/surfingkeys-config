/// <reference types="@surfingkeys-config-service/surfingkeys-types" />

import { getSecret } from '../lib/server-client';

// Default model - can be switched dynamically via RUNTIME('updateSettings', ...)
// Example: Update model to 'anthropic/claude-3.5-sonnet' by spreading
// ...settings.llm.custom and overriding the model field
const DEFAULT_MODEL = 'anthropic/claude-3.5-sonnet';

async function setupLLM() {
  try {
    const apiKey = await getSecret('openrouter-api-key');

    settings.llm.custom = {
      serviceUrl: 'https://api.openrouter.ai/api/v1/chat/completions',
      apiKey,
      model: DEFAULT_MODEL
    };

    console.log('LLM configured successfully');
  } catch (error) {
    console.error('Failed to setup LLM:', error);
    // Graceful degradation - feature won't work but config loads
  }
}

export { setupLLM };
