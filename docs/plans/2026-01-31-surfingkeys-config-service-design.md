# Surfingkeys Config Service - Design Document

**Date:** 2026-01-31
**Status:** Approved

## Overview

A monorepo project that provides a modular TypeScript config for the Surfingkeys browser extension, served via a local HTTP server. The same server handles secure retrieval of API keys and secrets from Proton Pass CLI for use in the extension.

## Project Goals

1. **Modular Config** - TypeScript config organized by feature domain, bundled to JavaScript
2. **Local HTTP Server** - Serves the config bundle and provides API endpoints
3. **Proton Pass Integration** - Retrieve API keys and secrets securely from Proton Pass CLI
4. **Daemon-Ready** - Docker Compose setup for easy installation as a background service
5. **Developer Experience** - Watch mode with auto-rebuild during development

## Architecture

### High-Level Structure

```
surfingkeys-config-service/
├── packages/
│   ├── surfingkeys-types/      # Type generation for Surfingkeys API
│   ├── config/                 # TypeScript config, builds to JS bundle
│   └── server/                 # Bun.serve HTTP server
├── scripts/
│   └── get-proton-creds.sh     # Helper to fetch Proton credentials
├── docs/
│   └── plans/                  # Design documents
├── docker-compose.yml          # Production daemon
├── docker-compose.dev.yml      # Development with watch mode
├── Dockerfile                  # Production build
├── Dockerfile.dev              # Development build
├── .env.example                # Environment template
└── package.json                # Workspace root
```

### Technology Stack

- **Monorepo:** Bun workspaces
- **Config Build:** Vite (TypeScript → JavaScript bundle)
- **Server Runtime:** Bun.js (Bun.serve)
- **Type Generation:** Docker + TypeScript compiler (existing tooling)
- **Deployment:** Docker Compose
- **Secret Management:** Proton Pass CLI

## Package Details

### 1. surfingkeys-types Package

**Purpose:** Generate TypeScript definitions from Surfingkeys source code for type-safe config development.

**Location:** `packages/surfingkeys-types/` (moved from root)

**Key Files:**
- `output/` - Generated .d.ts files
- `scripts/generate.sh` - Type generation script
- `docker/Dockerfile` - Generation container
- `workflows/generate-types.yml` - GitHub Actions workflow

**Usage:** Other packages reference as `workspace:*` dependency

### 2. config Package

**Purpose:** Modular TypeScript configuration that compiles to a single JavaScript bundle.

**Directory Structure:**
```
packages/config/
├── src/
│   ├── lib/
│   │   └── server-client.ts    # RUNTIME wrapper for API calls
│   ├── secrets/
│   │   └── proton.ts           # Proton Pass integration
│   ├── llm/
│   │   └── openrouter.ts       # LLM setup with API key
│   ├── navigation/             # Future: link hints, scrolling
│   ├── search/                 # Future: search shortcuts
│   └── index.ts                # Entry point
├── vite.config.ts
├── tsconfig.json
└── package.json
```

**Key Implementation - server-client.ts:**
```typescript
const SERVER_URL = `http://${import.meta.env.VITE_SERVER_HOST}:${import.meta.env.VITE_SERVER_PORT}`;

export function getSecret(name: string): Promise<string> {
  return new Promise((resolve, reject) => {
    RUNTIME('request', {
      url: `${SERVER_URL}/api/secrets/${name}`,
      timeout: 5000
    }, response => {
      if (response.error) {
        reject(new Error(`Server error: ${response.error}`));
      } else {
        resolve(JSON.parse(response.text).value);
      }
    });
  });
}
```

**Key Implementation - llm/openrouter.ts:**
```typescript
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
  } catch (error) {
    console.error('Failed to setup LLM:', error);
    // Graceful degradation - feature won't work but config loads
  }
}

setupLLM();
```

**Build:** Vite bundles to single IIFE at `dist/bundle.js`

**Environment Variables:**
- `VITE_SERVER_HOST` - Server hostname (baked into bundle)
- `VITE_SERVER_PORT` - Server port (baked into bundle)

### 3. server Package

**Purpose:** HTTP server that serves the config bundle and provides secret retrieval API.

**Directory Structure:**
```
packages/server/
├── src/
│   ├── index.ts                # Main server
│   ├── routes/
│   │   ├── static.ts           # Serve config bundle
│   │   └── secrets.ts          # Secrets API
│   └── lib/
│       └── proton-pass.ts      # Proton Pass CLI wrapper
└── package.json
```

**Key Implementation - index.ts:**
```typescript
import { serve } from 'bun';

const server = serve({
  port: process.env.SERVER_PORT || 16080,
  hostname: process.env.SERVER_HOST || '127.0.0.1',

  async fetch(req) {
    const url = new URL(req.url);

    if (url.pathname === '/config.js') {
      const file = Bun.file('/app/static/config.js');
      return new Response(file, {
        headers: { 'Content-Type': 'application/javascript' }
      });
    }

    if (url.pathname.startsWith('/api/secrets/')) {
      const name = url.pathname.split('/').pop();
      return handleGetSecret(name);
    }

    return new Response('Not Found', { status: 404 });
  }
});

console.log(`Server running at http://${server.hostname}:${server.port}`);
```

**Key Implementation - lib/proton-pass.ts:**
```typescript
import { $ } from 'bun';

export async function getSecret(name: string): Promise<string> {
  // Test mode returns mock data
  if (process.env.TEST_MODE === 'true') {
    const mockSecrets = {
      'openrouter-api-key': 'test-api-key-12345',
      'test-secret': 'test-value'
    };
    return mockSecrets[name] || '';
  }

  const result = await $`pass-cli item get ${name} --format json`.json();

  if (!result.data?.content?.itemData) {
    throw new Error(`Secret '${name}' not found in Proton Pass`);
  }

  return result.data.content.itemData.password
    || result.data.content.itemData.text
    || '';
}
```

**Key Implementation - routes/secrets.ts:**
```typescript
import { getSecret as getSecretFromProtonPass } from '../lib/proton-pass';

export async function handleGetSecret(name: string) {
  try {
    const value = await getSecretFromProtonPass(name);
    return Response.json({ value });
  } catch (error) {
    console.error(`Error fetching secret '${name}':`, error);
    return Response.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
```

**API Endpoints:**
- `GET /config.js` - Serves the bundled config
- `GET /api/secrets/:name` - Retrieves secret from Proton Pass

**Security:** No authentication, binds to localhost only (127.0.0.1)

## Docker Setup

### Production Dockerfile (Multi-stage)

```dockerfile
# Stage 1: Build config bundle
FROM oven/bun:1 AS config-builder
WORKDIR /app
COPY package.json bun.lockb ./
COPY packages/surfingkeys-types ./packages/surfingkeys-types
COPY packages/config ./packages/config
RUN bun install
RUN bun run build:config

# Stage 2: Server runtime
FROM oven/bun:1
WORKDIR /app

# Install Proton Pass CLI dependencies
RUN apt-get update && apt-get install -y curl jq && rm -rf /var/lib/apt/lists/*

# Install Proton Pass CLI
RUN curl -fsSL https://proton.me/download/pass-cli/install.sh | bash

# Copy server code
COPY packages/server ./packages/server
COPY package.json bun.lockb ./
RUN bun install --production

# Copy built config bundle from builder stage
COPY --from=config-builder /app/packages/config/dist/bundle.js /app/static/config.js

# Authenticate with Proton Pass on startup, then start server
CMD pass-cli login ${PROTON_EMAIL} && bun run packages/server/src/index.ts
```

### Development Dockerfile

```dockerfile
FROM oven/bun:1
WORKDIR /app

# Install Proton Pass CLI
RUN apt-get update && apt-get install -y curl jq && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://proton.me/download/pass-cli/install.sh | bash

# Copy package files
COPY package.json bun.lockb ./
COPY packages ./packages
RUN bun install

# Start: 1) auth, 2) vite watch, 3) server with watch
CMD ["/bin/bash", "-c", "\
  pass-cli login ${PROTON_EMAIL} && \
  cd packages/config && bun run vite build --watch & \
  cd packages/server && bun run --watch src/index.ts"]
```

### docker-compose.yml (Production)

```yaml
services:
  surfingkeys-server:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "${SERVER_PORT:-16080}:${SERVER_PORT:-16080}"
    environment:
      - SERVER_HOST=${SERVER_HOST:-127.0.0.1}
      - SERVER_PORT=${SERVER_PORT:-16080}
      - PROTON_EMAIL=${PROTON_EMAIL}
      - PROTON_PASS_PASSWORD=${PROTON_PASS_PASSWORD}
      - PROTON_PASS_TOTP=${PROTON_PASS_TOTP}
      - PROTON_PASS_EXTRA_PASSWORD=${PROTON_PASS_EXTRA_PASSWORD}
    restart: unless-stopped
```

### docker-compose.dev.yml (Development)

```yaml
services:
  surfingkeys-server-dev:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "${SERVER_PORT:-16080}:${SERVER_PORT:-16080}"
    environment:
      - SERVER_HOST=${SERVER_HOST:-127.0.0.1}
      - SERVER_PORT=${SERVER_PORT:-16080}
      - PROTON_EMAIL=${PROTON_EMAIL}
      - PROTON_PASS_PASSWORD=${PROTON_PASS_PASSWORD}
      - PROTON_PASS_TOTP=${PROTON_PASS_TOTP}
      - PROTON_PASS_EXTRA_PASSWORD=${PROTON_PASS_EXTRA_PASSWORD}
      - NODE_ENV=development
    volumes:
      # Mount config source for editing
      - ./packages/config/src:/app/packages/config/src:ro
      # Mount config build output
      - ./packages/config/dist:/app/static:ro
      # Mount server source for hot reload
      - ./packages/server/src:/app/packages/server/src:ro
```

## Environment Configuration

### .env.example

```bash
# Server configuration
SERVER_HOST=127.0.0.1
SERVER_PORT=16080

# Proton Pass authentication
PROTON_EMAIL=user@proton.me
PROTON_PASS_PASSWORD=
PROTON_PASS_TOTP=
PROTON_PASS_EXTRA_PASSWORD=
```

### Credential Helper Script

**scripts/get-proton-creds.sh:**
```bash
#!/bin/bash
# Retrieves Proton credentials from host's authenticated pass-cli

echo "Retrieving Proton credentials from pass-cli..."
PASSWORD=$(pass-cli item get proton-credentials --field password)
TOTP=$(pass-cli item get proton-credentials --field totp)
EXTRA_PASSWORD=$(pass-cli item get proton-credentials --field extra-password)

cat >> .env << EOF
PROTON_PASS_PASSWORD=${PASSWORD}
PROTON_PASS_TOTP=${TOTP}
PROTON_PASS_EXTRA_PASSWORD=${EXTRA_PASSWORD}
EOF

echo "Credentials written to .env"
```

**Usage:**
1. Ensure host's `pass-cli` is authenticated
2. Run `./scripts/get-proton-creds.sh`
3. Credentials are appended to `.env`
4. Docker Compose reads from `.env` on startup

## Data Flow

### Request Lifecycle - Retrieving an API Key

1. **Surfingkeys loads config:**
   - Browser extension requests `http://127.0.0.1:16080/config.js`
   - Server serves static bundle from `/app/static/config.js`
   - Bundle executes in content script context

2. **Config initialization:**
   - `llm/openrouter.ts` calls `getSecret('openrouter-api-key')`

3. **RUNTIME wrapper:**
   - `server-client.ts` wraps call in `RUNTIME('request', ...)`
   - Background script makes HTTP request (bypasses CORS)
   - Request goes to `http://127.0.0.1:16080/api/secrets/openrouter-api-key`

4. **Server handles request:**
   - Routes to `handleGetSecret('openrouter-api-key')`
   - Calls `getSecretFromProtonPass('openrouter-api-key')`

5. **Proton Pass CLI:**
   - Server executes `pass-cli item get openrouter-api-key --format json`
   - Parses JSON response
   - Returns secret value

6. **Response flows back:**
   - Server → Background script → Content script
   - LLM configured with API key
   - Surfingkeys ready to use

### Flow Diagram

```
Browser Extension
  ↓ (loads config URL)
Server: GET /config.js → static bundle
  ↓
Content Script executes bundle
  ↓ (RUNTIME('request'))
Background Script
  ↓ (HTTP GET)
Server: GET /api/secrets/:name
  ↓ (shell exec)
Proton Pass CLI
  ↓ (JSON response)
Server → Browser → Config initialization complete
```

## Error Handling

### Graceful Degradation

All secret fetching is wrapped in try-catch blocks. If the server is unreachable or a secret is missing:
- Error is logged to console
- Feature requiring the secret fails silently
- Rest of config continues to load and work

### Server Errors

- 500 response if Proton Pass CLI fails
- Detailed error logged server-side
- Client receives error object: `{ error: "message" }`

### Config Errors

- Timeouts on requests (5 seconds)
- Empty string returned on failure
- Allows config to load even if secrets unavailable

## Testing Strategy

### Integration Tests

**Test mock implementation:**
```typescript
// packages/server/src/lib/proton-pass.ts
export async function getSecret(name: string): Promise<string> {
  if (process.env.TEST_MODE === 'true') {
    const mockSecrets = {
      'openrouter-api-key': 'test-api-key-12345',
      'test-secret': 'test-value'
    };
    return mockSecrets[name] || '';
  }

  // Real implementation...
}
```

**Integration tests:**
```typescript
process.env.TEST_MODE = 'true';

test('GET /api/secrets/:name returns secret', async () => {
  const response = await fetch('http://127.0.0.1:16080/api/secrets/openrouter-api-key');
  const data = await response.json();

  expect(response.status).toBe(200);
  expect(data.value).toBe('test-api-key-12345');
});

test('GET /config.js serves bundle', async () => {
  const response = await fetch('http://127.0.0.1:16080/config.js');
  const text = await response.text();

  expect(response.headers.get('content-type')).toBe('application/javascript');
  expect(text).toContain('// Bundled config');
});
```

### Manual Testing

1. Load Surfingkeys config from `http://127.0.0.1:16080/config.js`
2. Open browser console
3. Verify LLM configured: `settings.llm.custom`
4. Test LLM chat feature

### Type Checking

```bash
cd packages/config
bun run tsc --noEmit
```

## Workspace Scripts

### Root package.json

```json
{
  "name": "surfingkeys-config-service",
  "private": true,
  "workspaces": [
    "packages/*"
  ],
  "scripts": {
    "build": "bun run build:types && bun run build:config",
    "build:types": "cd packages/surfingkeys-types/scripts && ./generate.sh",
    "build:config": "cd packages/config && bun run build",
    "dev": "docker compose -f docker-compose.dev.yml up",
    "start": "docker compose up -d",
    "stop": "docker compose down",
    "setup": "./scripts/get-proton-creds.sh",
    "logs": "docker compose logs -f",
    "test": "bun test",
    "typecheck": "cd packages/config && tsc --noEmit"
  }
}
```

### packages/config/package.json

```json
{
  "name": "@surfingkeys-config-service/config",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "vite build",
    "watch": "vite build --watch"
  },
  "dependencies": {
    "@surfingkeys-config-service/surfingkeys-types": "workspace:*"
  },
  "devDependencies": {
    "vite": "^5.0.0",
    "typescript": "^5.3.3"
  }
}
```

### packages/server/package.json

```json
{
  "name": "@surfingkeys-config-service/server",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "bun run src/index.ts",
    "dev": "bun run --watch src/index.ts"
  },
  "devDependencies": {
    "@types/bun": "latest"
  }
}
```

### packages/surfingkeys-types/package.json

```json
{
  "name": "@surfingkeys-config-service/surfingkeys-types",
  "private": true,
  "version": "0.0.0-dev",
  "types": "output/index.d.ts",
  "scripts": {
    "generate": "cd scripts && ./generate.sh"
  }
}
```

## Development Workflow

### Initial Setup

```bash
# Clone repository
git clone <repo-url>
cd surfingkeys-config-service

# Copy environment template
cp .env.example .env

# Install dependencies
bun install

# Get Proton credentials (requires authenticated pass-cli on host)
bun run setup

# Generate Surfingkeys types
bun run build:types

# Start development server
bun run dev
```

### Daily Development

```bash
# Start dev environment (if not running)
bun run dev

# Edit config files in packages/config/src/
# Vite watches and rebuilds automatically

# Refresh Surfingkeys to load new config
# In browser: Settings → Advanced mode → Load settings from → http://127.0.0.1:16080/config.js

# View logs
bun run logs

# Stop when done
bun run stop
```

### Production Daemon

```bash
# Start as background service
bun run start

# Check logs
bun run logs

# Stop service
bun run stop
```

## Future Enhancements

### Short-term
- Add navigation module (link hints, scrolling)
- Add search shortcuts module
- Publish surfingkeys-types to npm as `@types/surfingkeys`

### Medium-term
- Support for other secret backends (1Password CLI, etc.)
- Web UI for managing secrets
- Config hot-reload without manual browser refresh

### Long-term
- Bidirectional session sync with Emacs org-mode
- Additional Surfingkeys features (custom UI overlays, etc.)
- Native messaging integration for richer browser interactions

## Security Considerations

### Localhost-Only Binding

Server binds to `127.0.0.1` only, not accessible from network. Attack surface limited to local processes.

### No Authentication

Acceptable for localhost-only deployment. Adding authentication tokens would create friction without meaningful security improvement.

### Credential Storage

Proton Pass credentials stored in `.env` file:
- Should be in `.gitignore`
- File permissions should be restricted (`chmod 600 .env`)
- Alternative: Use host's pass-cli session (requires volume mounting)

### TOTP Timing

TOTP codes expire quickly (~30 seconds). Container must start and authenticate fast:
- Multi-stage build with caching minimizes startup time
- Run helper script immediately before `docker compose up`
- Consider persistent session if pass-cli supports it

## Open Questions

1. **Session Persistence:** Does Proton Pass CLI support persistent sessions to avoid re-authentication on container restart?
2. **Secret Refresh:** How to handle secret updates in Proton Pass? Restart server or add refresh endpoint?
3. **Multiple Users:** How to handle multi-user scenarios? Per-user config bundles?

## Success Criteria

- ✅ TypeScript config with full Surfingkeys type support
- ✅ Modular organization by feature domain
- ✅ Production-ready bundle served via HTTP
- ✅ Secure API key retrieval from Proton Pass
- ✅ Docker Compose daemon setup
- ✅ Development mode with auto-rebuild
- ✅ Graceful error handling and degradation
- ✅ Integration tests for core flows

## References

- [Surfingkeys GitHub](https://github.com/brookhong/Surfingkeys)
- [Proton Pass CLI](https://github.com/protonpass/pass-cli)
- [Bun Documentation](https://bun.sh/docs)
- [Vite Documentation](https://vitejs.dev/)
