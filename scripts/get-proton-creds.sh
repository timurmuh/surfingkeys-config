#!/bin/bash
# Retrieves Proton credentials from host's authenticated pass-cli

set -e

echo "Retrieving Proton credentials from pass-cli..."

# Check if pass-cli is available
if ! command -v pass-cli &> /dev/null; then
    echo "Error: pass-cli not found. Please install it first."
    exit 1
fi

# Get credentials from Proton Pass
PASSWORD=$(pass-cli item get proton-credentials --field password)
TOTP=$(pass-cli item get proton-credentials --field totp)
EXTRA_PASSWORD=$(pass-cli item get proton-credentials --field extra-password 2>/dev/null || echo "")

# Append to .env file
cat >> .env << EOF

# Proton Pass credentials (added by get-proton-creds.sh)
PROTON_PASS_PASSWORD=${PASSWORD}
PROTON_PASS_TOTP=${TOTP}
PROTON_PASS_EXTRA_PASSWORD=${EXTRA_PASSWORD}
EOF

echo "Credentials written to .env"
echo "You can now run: bun run dev"
