import { serve } from 'bun';
import { handleGetSecret } from './routes/secrets';
import { $ } from 'bun';
import { resolve } from 'path';
import { existsSync } from 'fs';

// Authenticate with Proton Pass on startup
async function authenticateProtonPass() {
  if (process.env.TEST_MODE === 'true') {
    console.log('Test mode: Skipping Proton Pass authentication');
    return;
  }

  try {
    await $`pass-cli login ${process.env.PROTON_EMAIL}`;
    console.log('Authenticated with Proton Pass');
  } catch (error) {
    console.error('Failed to authenticate with Proton Pass:', error);
    process.exit(1);
  }
}

// Determine config bundle path (Docker vs local)
function getConfigPath(): string {
  const dockerPath = '/app/static/config.js';
  const localPath = resolve(import.meta.dir, '../../config/dist/bundle.js');

  if (existsSync(dockerPath)) {
    return dockerPath;
  }
  return localPath;
}

// Start server
async function startServer() {
  await authenticateProtonPass();

  const configPath = getConfigPath();
  console.log(`Serving config from: ${configPath}`);

  const server = serve({
    port: parseInt(process.env.SERVER_PORT || '16080'),
    hostname: process.env.SERVER_HOST || '127.0.0.1',

    async fetch(req) {
      const url = new URL(req.url);

      // Serve config bundle
      if (url.pathname === '/config.js') {
        const file = Bun.file(configPath);
        return new Response(file, {
          headers: { 'Content-Type': 'application/javascript' }
        });
      }

      // API: Get secret
      if (url.pathname.startsWith('/api/secrets/')) {
        const name = url.pathname.split('/').pop();
        return handleGetSecret(name);
      }

      return new Response('Not Found', { status: 404 });
    }
  });

  console.log(`Server running at http://${server.hostname}:${server.port}`);
  console.log(`Config available at http://${server.hostname}:${server.port}/config.js`);
}

startServer();
