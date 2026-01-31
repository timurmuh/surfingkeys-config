# Using Surfingkeys Types in TypeScript Projects

This guide explains how to use the generated Surfingkeys types in a TypeScript project where you compile modular code into a JavaScript bundle.

## Quick Start

### 1. Generate Types

```bash
cd surfingkeys-types/scripts
./generate.sh  # Uses latest Surfingkeys release by default
```

This creates `surfingkeys-types/output/` with:
- `index.d.ts` - Main type definitions
- `package.json` - Version matches Surfingkeys version
- Complete module structure

### 2. Add Types to Your TypeScript Project

You have three options:

#### Option A: Local Types Directory (Recommended for Development)

Copy the output to your project:

```bash
# In your TypeScript project root
cp -r path/to/surfingkeys-types/output ./types/surfingkeys
```

Update your `tsconfig.json`:

```json
{
  "compilerOptions": {
    "typeRoots": [
      "./node_modules/@types",
      "./types"
    ]
  }
}
```

Or use `types` array:

```json
{
  "compilerOptions": {
    "types": ["surfingkeys"]
  }
}
```

#### Option B: Path Mapping

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "surfingkeys-types": ["./types/surfingkeys"]
    }
  }
}
```

#### Option C: Triple-Slash Directive

In your entry file (e.g., `src/index.ts`):

```typescript
/// <reference types="../types/surfingkeys" />
```

## Project Structure Example

```
my-surfingkeys-config/
├── src/
│   ├── index.ts              # Entry point
│   ├── mappings.ts           # Key mappings
│   ├── themes.ts             # Visual customizations
│   └── utils.ts              # Helper functions
├── types/
│   └── surfingkeys/          # Copied from surfingkeys-types/output
│       ├── index.d.ts
│       ├── content_scripts/
│       └── package.json
├── dist/
│   └── bundle.js             # Compiled output
├── tsconfig.json
├── webpack.config.js         # or rollup.config.js
└── package.json
```

## TypeScript Configuration

### tsconfig.json Example

```json
{
  "compilerOptions": {
    "target": "ES2015",
    "module": "ESNext",
    "lib": ["ES2015", "DOM"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "moduleResolution": "node",
    "typeRoots": [
      "./node_modules/@types",
      "./types"
    ]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Writing Modular Code

### src/index.ts

```typescript
// Import your modules
import { setupMappings } from './mappings';
import { applyTheme } from './themes';
import { initUtils } from './utils';

// The global 'api' is now typed!
// No need for import statement - it's declared as global

// Initialize your config
setupMappings();
applyTheme();
initUtils();
```

### src/mappings.ts

```typescript
export function setupMappings() {
  // Full autocomplete for api methods
  api.mapkey('<Space>f', 'Open link in hints', () => {
    api.Hints.create('a', api.Hints.dispatchMouseClick);
  });

  api.vmapkey('y', 'Yank text', () => {
    const selection = window.getSelection();
    if (selection) {
      api.Clipboard.write(selection.toString());
    }
  });

  api.mapkey('<Space>t', 'Open new tab', () => {
    api.RUNTIME('openLink', {
      tab: { tabbed: true, active: false },
      url: 'https://example.com'
    });
  });
}
```

### src/themes.ts

```typescript
export function applyTheme() {
  // Type-safe theme configuration
  api.Hints.style('border: solid 2px #4CAF50; padding: 1px;');
  api.Visual.style('marks', 'background-color: #4CAF50;');
}
```

### src/utils.ts

```typescript
export function initUtils() {
  // Create helper functions with full type support
  api.mapkey('<Space>c', 'Copy URL', () => {
    api.Clipboard.write(window.location.href);
    api.Front.showBanner('URL copied!', 1000);
  });
}
```

## Using the SurfingkeysAPI Type

If you need to reference the API type (e.g., for function parameters):

```typescript
import type { SurfingkeysAPI } from '../types/surfingkeys';

// Use in function signatures
function customMapping(apiInstance: SurfingkeysAPI) {
  apiInstance.mapkey('x', 'Custom action', () => {
    console.log('Custom!');
  });
}

// Though typically you just use the global 'api':
customMapping(api);
```

## Building Your Bundle

### With Webpack

```javascript
// webpack.config.js
const path = require('path');

module.exports = {
  entry: './src/index.ts',
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      },
    ],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js'],
  },
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
  },
};
```

### With Rollup

```javascript
// rollup.config.js
import typescript from '@rollup/plugin-typescript';

export default {
  input: 'src/index.ts',
  output: {
    file: 'dist/bundle.js',
    format: 'iife',
  },
  plugins: [typescript()],
};
```

### With esbuild (Fastest)

```bash
esbuild src/index.ts --bundle --outfile=dist/bundle.js
```

Or in package.json:

```json
{
  "scripts": {
    "build": "esbuild src/index.ts --bundle --outfile=dist/bundle.js",
    "watch": "esbuild src/index.ts --bundle --outfile=dist/bundle.js --watch"
  }
}
```

## Loading in Surfingkeys

After building, configure Surfingkeys to load your bundle:

```javascript
// .surfingkeysrc (minimal - just loads your bundle)
settings.loadBundle = 'path/to/dist/bundle.js';
```

Or serve it from a local server:

```javascript
// .surfingkeysrc
const script = document.createElement('script');
script.src = 'http://localhost:8080/bundle.js';
document.head.appendChild(script);
```

## Version Management

The generated types match the Surfingkeys version:

```bash
# Generate for latest release (default)
./generate.sh

# Generate for specific version
./generate.sh --version v1.16.2

# Check version in package.json
cat surfingkeys-types/output/package.json | grep version
```

The `package.json` includes metadata:

```json
{
  "name": "surfingkeys-types",
  "version": "1.16.2",
  "description": "TypeScript definitions for Surfingkeys v1.16.2",
  "types": "index.d.ts",
  "metadata": {
    "surfingkeysVersion": "v1.16.2",
    "generatedAt": "2024-01-31T12:00:00Z"
  }
}
```

## Updating Types

When Surfingkeys releases a new version:

```bash
# Regenerate types
cd surfingkeys-types/scripts
./generate.sh  # Auto-fetches latest release

# Update your project
rm -rf types/surfingkeys
cp -r ../output types/surfingkeys

# Rebuild
npm run build
```

## Publishing to npm (Optional)

If you want to publish these types to npm for easy installation:

1. Update package.json in output/:

```json
{
  "name": "@yourusername/surfingkeys-types",
  "version": "1.16.2",
  "description": "TypeScript definitions for Surfingkeys",
  "types": "index.d.ts",
  "files": [
    "**/*.d.ts"
  ]
}
```

2. Publish:

```bash
cd surfingkeys-types/output
npm publish --access public
```

3. Install in projects:

```bash
npm install --save-dev @yourusername/surfingkeys-types
```

## Troubleshooting

### "Cannot find name 'api'"

Make sure:
1. Types are in `typeRoots` or referenced correctly
2. Your IDE has reloaded (restart TypeScript server)
3. `tsconfig.json` includes your source files

### "Module not found"

Check path in `reference types` or `typeRoots` matches your directory structure.

### Autocomplete not working

1. Verify `index.d.ts` exists in types directory
2. Check `package.json` has correct `types` field
3. Restart TypeScript language server in your IDE

### Build errors

Ensure `skipLibCheck: true` in tsconfig.json to skip checking declaration files for errors.

## Example Project

Complete example project structure:

```bash
# Clone this repo
git clone https://github.com/yourusername/surfingkeys-config-ts

# Install dependencies
npm install

# Generate types
cd surfingkeys-types/scripts && ./generate.sh && cd ../..

# Copy types
cp -r surfingkeys-types/output types/surfingkeys

# Build
npm run build

# Output: dist/bundle.js
```

## Best Practices

1. **Version Locking**: Pin to specific Surfingkeys version in production
2. **Type Checking**: Run `tsc --noEmit` in CI to catch type errors
3. **Regenerate on Updates**: Update types when updating Surfingkeys
4. **Commit Types**: Commit generated types to version control
5. **Document API Usage**: Add JSDoc comments to your helper functions

## Advanced: Custom Type Augmentation

If you need to extend the API with custom types:

```typescript
// src/types/custom.d.ts
declare global {
  interface Window {
    myCustomSurfingkeysUtil: () => void;
  }
}

export {};
```

## Questions?

See [README.md](./README.md) for general documentation or [CHANGES.md](./CHANGES.md) for recent updates.
