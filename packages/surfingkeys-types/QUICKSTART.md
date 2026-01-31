# Surfingkeys Types - Quick Start

## Generate Types (One Command)

```bash
cd surfingkeys-types/scripts
./generate.sh
```

Output: `surfingkeys-types/output/` (with index.d.ts and module structure)

**Note**: Automatically uses the latest Surfingkeys release. The package.json version will match!

## Use in Your Config

Add this line to the top of your `.surfingkeysrc`:

```javascript
/// <reference types="./surfingkeys-types/output" />
```

Now you get autocomplete for all Surfingkeys APIs!

## Common Options

```bash
# Generate for specific version
./generate.sh --version v1.16.2

# Clean output first
./generate.sh --clean

# Show help
./generate.sh --help
```

## Copy to Another Project

```bash
cp -r surfingkeys-types /path/to/other/project/
```

## Enable GitHub Actions

```bash
cp surfingkeys-types/workflows/generate-types.yml .github/workflows/
```

## Example Usage

### JavaScript (.surfingkeysrc)

```javascript
/// <reference types="./surfingkeys-types/output" />

// Autocomplete works!
api.mapkey('<Space>f', 'Open link', function() {
    api.Hints.create('a', api.Hints.dispatchMouseClick);
});

api.Clipboard.read(function(response) {
    console.log(response.data);
});

api.RUNTIME('getTabs', {queryInfo: {active: true}}, function(tabs) {
    console.log(tabs[0].url);
});
```

### TypeScript Projects

For modular TypeScript that compiles to a bundle:

1. Copy types: `cp -r surfingkeys-types/output ./types/surfingkeys`
2. Add to `tsconfig.json`:
   ```json
   {
     "compilerOptions": {
       "typeRoots": ["./node_modules/@types", "./types"]
     }
   }
   ```
3. Write TypeScript with full autocomplete
4. Build and load in Surfingkeys

See **[TYPESCRIPT-USAGE.md](./TYPESCRIPT-USAGE.md)** for complete guide.

## Troubleshooting

**Docker not found?**
- Install Docker Desktop

**Permission errors?**
```bash
sudo chown -R $USER:$USER surfingkeys-types/output
```

**Need help?**
```bash
./generate.sh --help
```

---

For full documentation, see [README.md](./README.md)
