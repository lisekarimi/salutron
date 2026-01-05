#!/bin/bash

# terraform/azure/scripts/destroy.sh
# This script destroys the Azure environment

set -e

ENVIRONMENT=${1:-dev}

if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
  echo "Error: Environment must be dev, test, or prod"
  exit 1
fi

echo "🗑️  Destroying ${ENVIRONMENT} environment..."

# Load secrets from .env if available (local), otherwise use environment variables (CI)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [ -f "$PROJECT_ROOT/.env" ]; then
  export $(grep -v '^#' $PROJECT_ROOT/.env | xargs)
  echo "✅ Loaded secrets from .env"
else
  echo "✅ Using secrets from environment variables"
fi

# Verify required secrets are set
if [ -z "$OPENAI_API_KEY" ]; then
  echo "❌ Error: OPENAI_API_KEY is required"
  exit 1
fi

# Change to terraform directory
cd "$SCRIPT_DIR/.."

terraform init -input=false

terraform workspace select "$ENVIRONMENT"

terraform destroy \
  -var="environment=$ENVIRONMENT" \
  -var="openai_api_key=$OPENAI_API_KEY" \
  -auto-approve

echo ""
echo "✅ Environment destroyed successfully!"
