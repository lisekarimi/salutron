#!/bin/bash

# terraform/gcp/scripts/destroy.sh
# This script destroys the GCP environment

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

# Change to terraform directory
cd "$SCRIPT_DIR/.."

terraform workspace select "$ENVIRONMENT"

# Use prod.tfvars for production
if [ "$ENVIRONMENT" = "prod" ]; then
  terraform destroy \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY" \
    -var-file=prod.tfvars
else
  terraform destroy \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY"
fi

# Remind about manual DNS cleanup for prod
if [ "$ENVIRONMENT" = "prod" ]; then
  CUSTOM_DOMAIN=$(grep 'custom_domain' prod.tfvars 2>/dev/null | cut -d'"' -f2)
  if [ ! -z "$CUSTOM_DOMAIN" ]; then
    echo ""
    echo "⚠️  Don't forget to manually remove DNS record from your DNS provider:"
    echo "  - CNAME record: $CUSTOM_DOMAIN → ghs.googlehosted.com"
  fi
fi

echo ""
echo "✅ Environment destroyed successfully!"
