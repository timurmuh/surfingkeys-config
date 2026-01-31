# Surfingkeys TypeScript Definition Generator

A Docker-based tooling setup to generate TypeScript `.d.ts` files from the [Surfingkeys](https://github.com/brookhong/Surfingkeys) repository. This enables autocomplete and type checking in your `.surfingkeysrc` configuration files.

## Features

- **Automated Type Generation**: Generates TypeScript definitions from JSDoc comments in Surfingkeys source code
- **Docker Isolation**: Clones and builds in a container, avoiding git-in-git conflicts
- **Version Flexibility**: Generate types for any version, branch, or fork
- **CI/CD Ready**: Includes GitHub Actions workflow for automation
- **Portable**: Self-contained directory that can be copied to other projects

## Quick Start

### Prerequisites

- Docker installed and running
- Bash (or WSL/Git Bash on Windows)

### Generate Types

```bash
cd surfingkeys-types/scripts
./generate.sh
```

This will:
- Auto-fetch the latest Surfingkeys release version
- Generate TypeScript definitions in `surfingkeys-types/output/`
- Create `package.json` with matching version number
- Preserve proper module structure

**For TypeScript projects**, see [TYPESCRIPT-USAGE.md](./TYPESCRIPT-USAGE.md) for detailed setup instructions.

## Usage

### Basic Generation

```bash
# Generate from latest master
./generate.sh

# Generate for specific version
./generate.sh --version v1.16.2

# Clean output directory first
./generate.sh --clean

# Custom output directory
./generate.sh --output /tmp/types
```

### Command-Line Options

```
-o, --output DIR        Output directory (default: ../output)
-v, --version VERSION   Surfingkeys version/branch (default: latest release)
-r, --repo URL          Repository URL (for forks)
-c, --clean             Clean output directory first
-h, --help              Show help message
```

**Note**: Surfingkeys doesn't use version tags. By default, the script uses the `master` branch. You can specify a branch, tag, or commit hash with `-v`. The generated `package.json` version will be `0.0.0-dev` for master, or match the tag/version you specify.

### Environment Variables

You can also use environment variables:

```bash
export OUTPUT_DIR=/tmp/surfingkeys-types
export SURFINGKEYS_VERSION=v1.16.2
./generate.sh
```

## Version Management

The generated types track the Surfingkeys source version:

```bash
# Generate from master branch (default)
./generate.sh

# Generate from specific commit/branch
./generate.sh --version 61af39a
./generate.sh --version mv3

# Check generated version
cat ../output/package.json | grep version
```

**Note**: Surfingkeys doesn't use version tags in its repository. The `package.json` includes:
- `version`: `0.0.0-dev` for master/branches, or matches version if you specify one
- `metadata.surfingkeysVersion`: The branch/commit/tag used
- `metadata.generatedAt`: Generation timestamp

Example for master:
```json
{
  "name": "surfingkeys-types",
  "version": "0.0.0-dev",
  "description": "TypeScript definitions for Surfingkeys master",
  "types": "index.d.ts",
  "metadata": {
    "surfingkeysVersion": "master",
    "generatedAt": "2024-01-31T12:00:00Z"
  }
}
```

If you need a specific version number for your project, specify it manually:
```bash
./generate.sh --version master  # Then edit package.json version field
```

## Using Generated Types

### In Your .surfingkeysrc

Add a reference to the generated types at the top of your `.surfingkeysrc`:

```javascript
/// <reference types="./surfingkeys-types/output" />

// Now you get autocomplete and type checking!
api.mapkey('<Space>f', 'Open link', function() {
    api.Hints.create('a', api.Hints.dispatchMouseClick);
});

api.RUNTIME('getTabs', {queryInfo: {active: true}}, function(tabs) {
    console.log(tabs[0].url);
});

api.Clipboard.read(function(response) {
    console.log(response.data);
});
```

### With VS Code

1. Add the reference directive (as shown above)
2. Open `.surfingkeysrc` in VS Code
3. Enable JavaScript language features
4. Enjoy autocomplete, parameter hints, and inline documentation

### With TypeScript Projects

For modular TypeScript projects that compile to a bundle, see the comprehensive guide: **[TYPESCRIPT-USAGE.md](./TYPESCRIPT-USAGE.md)**

Quick setup:
1. Copy `surfingkeys-types/output/` to your project's `types/surfingkeys/`
2. Configure `tsconfig.json` typeRoots
3. Write modular TypeScript code with full autocomplete
4. Compile to bundle.js and load in Surfingkeys

The global `api` object is automatically typed - no imports needed!

## CI/CD Integration

### GitHub Actions

Copy the workflow file to your project:

```bash
cp surfingkeys-types/workflows/generate-types.yml .github/workflows/
```

The workflow:
- Runs on push to master
- Runs on version tags (`v*`)
- Allows manual dispatch with version selection
- Runs weekly to catch upstream updates
- Uploads artifacts for download
- Creates GitHub releases for version tags

### Triggers

The workflow runs on:

1. **Push to master**: Generates types from latest master
2. **Version tags**: Generates types for that specific version
3. **Manual dispatch**: Select any version/branch via workflow_dispatch
4. **Weekly schedule**: Runs every Monday to catch upstream updates

### Artifacts

Generated types are uploaded as artifacts and retained for 90 days. Download from the Actions tab.

## Copying to Other Projects

This entire directory is self-contained and portable. To use in another project:

1. **Copy the directory**:
   ```bash
   cp -r surfingkeys-types /path/to/other/project/
   ```

2. **Set up GitHub Actions** (optional):
   ```bash
   cp surfingkeys-types/workflows/generate-types.yml .github/workflows/
   ```

3. **Generate types**:
   ```bash
   cd surfingkeys-types/scripts
   ./generate.sh
   ```

## Architecture

### Directory Structure

```
surfingkeys-types/
├── docker/
│   └── Dockerfile               # Type generation container
├── scripts/
│   └── generate.sh              # Orchestration script
├── workflows/
│   └── generate-types.yml       # GitHub Actions workflow
├── output/                      # Generated types (gitignored)
│   ├── index.d.ts               # Main entry point - declares global api
│   ├── content_scripts/         # Core API type definitions
│   │   └── common/
│   │       ├── api.d.ts         # Main API factory
│   │       ├── runtime.d.ts     # RUNTIME API
│   │       ├── clipboard.d.ts   # Clipboard API
│   │       └── utils.d.ts       # Utility functions
│   ├── user_scripts/            # User script types
│   ├── common/                  # Common utilities
│   └── package.json             # Type package metadata
├── .gitignore
└── README.md                    # This file
```

### How It Works

1. **Docker Build**: Builds a container with Node.js 22 and clones Surfingkeys
2. **TypeScript Compilation**: Uses TypeScript's JSDoc compilation (`--allowJs --declaration --emitDeclarationOnly`)
3. **Post-Processing**: Creates `index.d.ts` that declares the global `api` object
4. **Output**: Preserves module structure with proper TypeScript declarations

### Source Files

Types are generated from these Surfingkeys files:

- `src/user_scripts/**/*.js` - User-facing API exports
- `src/content_scripts/common/*.js` - Core API implementations
  - `api.js` - Main API (mapkey, vmapkey, etc.)
  - `clipboard.js` - Clipboard API
  - `hints.js` - Hints API
  - `normal.js` - Normal mode API
  - `visual.js` - Visual mode API

## Troubleshooting

### Docker Build Fails

**Problem**: Docker build fails with network errors

**Solution**: Check your internet connection and try again. The build clones from GitHub.

### No Types Generated

**Problem**: Script completes but no `.d.ts` files created

**Solution**:
- Check that the Surfingkeys version exists
- Try with `--version master`
- Check Docker logs: `docker logs $(docker ps -lq)`

### TypeScript Errors in Generated Types

**Problem**: Generated `.d.ts` file has TypeScript errors

**Solution**: This can happen if JSDoc comments are incomplete. The types are generated from existing JSDoc, so quality depends on source documentation.

### Permission Errors

**Problem**: Cannot write to output directory

**Solution**: Ensure the output directory is writable. Docker runs as root, so files are owned by root. Fix with:
```bash
sudo chown -R $USER:$USER surfingkeys-types/output
```

### Git-in-Git Conflicts

**Problem**: Git complains about nested repositories

**Solution**: This is why we use Docker! The Surfingkeys repo is cloned inside the container, not on your host system.

## Advanced Usage

### Generate Types for a Fork

```bash
./generate.sh \
  --repo https://github.com/your-fork/Surfingkeys.git \
  --version your-branch
```

### Run Docker Directly

If you prefer not to use the script:

```bash
# Build image
docker build \
  --build-arg SURFINGKEYS_VERSION=master \
  -t surfingkeys-types:latest \
  -f docker/Dockerfile \
  docker/..

# Run container
docker run --rm \
  -v $(pwd)/output:/output \
  surfingkeys-types:latest
```

### Customize TypeScript Config

Edit the `tsconfig.declarations.json` creation in `docker/Dockerfile` to adjust compilation settings.

## API Coverage

The generated types include:

- **Core API**: mapkey, vmapkey, imapkey, map, unmap, etc.
- **RUNTIME**: Browser runtime API wrapper
- **Clipboard**: Read/write clipboard operations
- **Hints**: Create and style hints
- **Normal**: Normal mode operations
- **Visual**: Visual mode operations
- **Front**: Frontend UI operations

119+ JSDoc annotations are converted to TypeScript types.

## Performance

- **First run**: 3-5 minutes (Docker build + npm install)
- **Subsequent runs**: 1-2 minutes (with Docker layer cache)
- **CI with cache**: 2-3 minutes

## Dependencies

### Host System

- Docker (required)
- Bash (for script, or run Docker directly)

### Docker Container (automatic)

- Node.js 22
- npm
- git
- TypeScript (from Surfingkeys package.json)
- All Surfingkeys dependencies

## License

This tooling is MIT licensed. Generated types are based on Surfingkeys (MIT licensed).

## Contributing

Suggestions and improvements welcome! This is a self-contained tooling setup, so changes should maintain portability.

## Future Enhancements

Potential improvements:

- Publish to npm as `@types/surfingkeys`
- Add declaration maps for source navigation
- Enhanced JSDoc in Surfingkeys for better types
- Validation tests for type accuracy
- Multi-version support (generate for multiple versions simultaneously)

## Support

For issues with:
- **This tooling**: Open an issue in your project
- **Surfingkeys itself**: https://github.com/brookhong/Surfingkeys/issues
- **Generated type accuracy**: Depends on JSDoc in Surfingkeys source

## Acknowledgments

- [Surfingkeys](https://github.com/brookhong/Surfingkeys) by brookhong
- TypeScript team for JSDoc compilation support
