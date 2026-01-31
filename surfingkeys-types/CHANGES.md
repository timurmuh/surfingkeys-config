# Changes to Type Generation Approach

## Problem with Original Approach

The initial implementation concatenated all `.d.ts` files into a single namespace, which caused TypeScript errors:

1. **"A declare modifier cannot be used in an already ambient context"** - Putting `declare` statements inside `declare namespace` created double-ambient context
2. **"A default export can only be used in an ECMAScript-style module"** - Default exports don't work inside namespaces
3. **"A module cannot have multiple default exports"** - Multiple files with default exports were combined
4. **Import statements interspersed** - Each file's imports were concatenated, breaking module structure

## New Approach

Instead of concatenating, we now:

1. **Preserve Module Structure**: Keep all generated `.d.ts` files in their original directory structure
2. **Create Global Declaration**: The `index.d.ts` declares the global `api` object that users actually use
3. **Use TypeScript's Module System**: Let TypeScript handle imports and exports naturally

### Output Structure

```
surfingkeys-types/output/
├── index.d.ts                    # Main entry - declares global api
├── content_scripts/common/
│   ├── api.d.ts                  # createAPI factory function
│   ├── runtime.d.ts              # RUNTIME function
│   ├── clipboard.d.ts            # Clipboard API
│   └── utils.d.ts                # Utility functions
├── user_scripts/
│   └── index.d.ts                # User script entry
├── common/
│   └── utils.d.ts                # Common utilities
└── package.json                  # Points to index.d.ts
```

### index.d.ts Content

```typescript
/// <reference path="./content_scripts/common/api.d.ts" />
/// <reference path="./content_scripts/common/runtime.d.ts" />
/// <reference path="./content_scripts/common/clipboard.d.ts" />
/// <reference path="./content_scripts/common/utils.d.ts" />

import type createAPI from './content_scripts/common/api';

/**
 * The global Surfingkeys API object available in .surfingkeysrc
 */
declare global {
    const api: ReturnType<typeof createAPI>;
}

// Also export the API type for use in modules
export type SurfingkeysAPI = ReturnType<typeof createAPI>;
```

### How It Works

1. **Global Declaration**: `declare global { const api: ... }` makes `api` available globally
2. **Type Inference**: `ReturnType<typeof createAPI>` extracts the return type from the factory function
3. **Reference Paths**: Triple-slash directives ensure all dependencies are loaded
4. **Module Export**: `export type SurfingkeysAPI` allows importing the type in modules if needed

### Usage

In your `.surfingkeysrc`:

```javascript
/// <reference types="./surfingkeys-types/output" />

// Now 'api' is recognized with full type information
api.mapkey('<Space>f', 'Open link', function() {
    api.Hints.create('a', api.Hints.dispatchMouseClick);
});
```

## Benefits

1. **No TypeScript Errors**: Proper module structure eliminates all ambient context issues
2. **Better Autocomplete**: TypeScript can follow imports and provide better suggestions
3. **Maintainable**: Module structure matches source code organization
4. **Flexible**: Can import specific types if needed: `import type { SurfingkeysAPI } from './surfingkeys-types/output'`

## Changes to Scripts

### generate.sh
- Removed file concatenation logic
- Added index.d.ts generation with global declaration
- Updated info messages to reference directory instead of single file

### generate-types.yml
- Updated post-processing to match generate.sh
- Changed artifact upload to include entire output directory
- Updated display messages

### Documentation
- Updated all references from `/// <reference path="..." />` to `/// <reference types="..." />`
- Updated directory structure diagrams
- Added explanation of module structure

## Migration

If you were using the old concatenated approach:

**Before:**
```javascript
/// <reference path="./surfingkeys-types/output/surfingkeys.d.ts" />
```

**After:**
```javascript
/// <reference types="./surfingkeys-types/output" />
```

The API usage remains exactly the same - only the reference directive changes.
