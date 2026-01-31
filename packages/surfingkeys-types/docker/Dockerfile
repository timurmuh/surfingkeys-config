# Surfingkeys TypeScript Definition Generator
# Base image: Node.js 22 LTS on Alpine Linux
FROM node:22-alpine

# Build arguments for flexibility
ARG SURFINGKEYS_REPO=https://github.com/brookhong/Surfingkeys.git
ARG SURFINGKEYS_VERSION=master

# Install git for cloning
RUN apk add --no-cache git

# Set working directory
WORKDIR /surfingkeys

# Clone Surfingkeys repository
RUN git clone --depth 1 --branch ${SURFINGKEYS_VERSION} ${SURFINGKEYS_REPO} . || \
    git clone --depth 1 ${SURFINGKEYS_REPO} .

# Install dependencies
RUN npm install --legacy-peer-deps

# Create custom tsconfig for declaration generation
RUN cat > tsconfig.declarations.json << 'EOF'
{
  "compilerOptions": {
    "allowJs": true,
    "declaration": true,
    "emitDeclarationOnly": true,
    "declarationDir": "/output",
    "skipLibCheck": true,
    "noEmit": false,
    "strict": false,
    "moduleResolution": "node",
    "esModuleInterop": true,
    "removeComments": false,
    "target": "ES2015",
    "module": "commonjs",
    "lib": ["ES2015", "DOM"],
    "suppressImplicitAnyIndexErrors": true,
    "noImplicitAny": false,
    "stripInternal": true
  },
  "include": [
    "src/user_scripts/**/*.js",
    "src/content_scripts/common/*.js"
  ],
  "exclude": [
    "node_modules",
    "dist",
    "tests",
    "**/*.test.js",
    "**/*.spec.js"
  ]
}
EOF

# Create output directory
RUN mkdir -p /output

# Generate TypeScript declarations
# Note: We ignore errors because some files have JSDoc issues, but we still get useful types
CMD npx tsc --project tsconfig.declarations.json || true
