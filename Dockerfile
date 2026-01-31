# Stage 1: Build config bundle
FROM oven/bun:1 AS config-builder
WORKDIR /app

# Copy workspace configuration
COPY package.json bun.lock ./

# Copy packages
COPY packages/surfingkeys-types ./packages/surfingkeys-types
COPY packages/config ./packages/config

# Install dependencies and build
RUN bun install
RUN cd packages/config && bun run build

# Stage 2: Server runtime
FROM oven/bun:1
WORKDIR /app

# Install Proton Pass CLI dependencies
RUN apt-get update && apt-get install -y curl jq && rm -rf /var/lib/apt/lists/*

# Install Proton Pass CLI
RUN curl -fsSL https://proton.me/download/pass-cli/install.sh | bash

# Copy workspace configuration
COPY package.json bun.lock ./

# Copy server package
COPY packages/server ./packages/server

# Install production dependencies
RUN bun install --production

# Copy built config bundle from builder stage
COPY --from=config-builder /app/packages/config/dist/bundle.js /app/static/config.js

ENV NODE_ENV=production

# Authenticate and start server
CMD pass-cli login ${PROTON_EMAIL} && bun run packages/server/src/index.ts
