/// <reference types="@surfingkeys-config-service/surfingkeys-types" />

// Import and initialize modules
import { setupLLM } from './llm/openrouter';

// Initialize LLM
setupLLM();

// Export for potential programmatic access
export { setupLLM };
