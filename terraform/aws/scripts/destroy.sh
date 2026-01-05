#!/bin/bash

# terraform/aws/scripts/destroy.sh
# This script is used to destroy the environment

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
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
terraform init -input=false \
  -backend-config="bucket=salutron-terraform-state-${AWS_ACCOUNT_ID}" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=salutron-terraform-locks" \
  -backend-config="encrypt=true"

terraform workspace select "$ENVIRONMENT"

# Use prod.tfvars for production
if [ "$ENVIRONMENT" = "prod" ]; then
  terraform destroy \
    -var-file=prod.tfvars \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY"
else
  terraform destroy \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY"
fi

# Remind about manual Cloudflare cleanup for prod
if [ "$ENVIRONMENT" = "prod" ]; then
  echo ""
  echo "⚠️  Don't forget to manually remove DNS records from Cloudflare:"
  echo "  - awsterraform CNAME record"
  echo "  - 2 validation CNAME records (_9224... and _e750...)"
fi
