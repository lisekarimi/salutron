#!/bin/bash

# terraform/scripts/destroy.sh
# This script is used to destroy the environment

set -e

ENVIRONMENT=${1:-dev}

if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
  echo "Error: Environment must be dev, test, or prod"
  exit 1
fi

echo "🗑️  Destroying ${ENVIRONMENT} environment..."

# Load secrets from .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ -f "$PROJECT_ROOT/.env" ]; then
  export $(grep -v '^#' $PROJECT_ROOT/.env | xargs)
  echo "✅ Loaded secrets from .env"
else
  echo "❌ Error: .env file not found at $PROJECT_ROOT/.env"
  exit 1
fi

# Change to terraform directory
cd "$SCRIPT_DIR/.."

terraform workspace select "$ENVIRONMENT"
terraform destroy \
  -var="environment=$ENVIRONMENT" \
  -var="openai_api_key=$OPENAI_API_KEY"
