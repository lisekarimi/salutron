#!/bin/bash

# terraform/azure/scripts/deploy.sh
# This script deploys the application to Azure Container Apps

set -e

ENVIRONMENT=${1:-dev}

if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
  echo "Error: Environment must be dev, test, or prod"
  exit 1
fi

echo "🚀 Starting full deployment to ${ENVIRONMENT}..."

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

# ==========================================
# Step 1: Create Container Registry
# ==========================================
echo "📦 Step 1/3: Creating Azure Container Registry..."
cd "$SCRIPT_DIR/.."

terraform init -input=false \
  -backend-config="resource_group_name=salutron-rg" \
  -backend-config="storage_account_name=salutronterraformstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=azure-${ENVIRONMENT}.tfstate"

if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
  terraform workspace new "$ENVIRONMENT"
else
  terraform workspace select "$ENVIRONMENT"
fi

terraform apply \
  -target=azurerm_container_registry.acr \
  -var="environment=$ENVIRONMENT" \
  -var="openai_api_key=$OPENAI_API_KEY" \
  -auto-approve

cd "$PROJECT_ROOT"

# ==========================================
# Step 2: Build and Push Docker Image
# ==========================================
echo "🐳 Step 2/3: Building and pushing Docker image..."

PROJECT_NAME=$(python3 -c "import re; print(re.search('name = \"(.*)\"', open('pyproject.toml').read()).group(1))")
ACR_NAME="${PROJECT_NAME}${ENVIRONMENT}acr"

# Construct ACR URL (Azure uses predictable naming)
ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"
echo "DEBUG: ACR_LOGIN_SERVER = ${ACR_LOGIN_SERVER}"
echo "DEBUG: ACR_NAME = ${ACR_NAME}"

cd "$PROJECT_ROOT"

# Login to ACR
az acr login --name $ACR_NAME

# Build, tag, and push
docker build -t ${PROJECT_NAME}:latest .
docker tag ${PROJECT_NAME}:latest ${ACR_LOGIN_SERVER}/${PROJECT_NAME}:latest
docker push ${ACR_LOGIN_SERVER}/${PROJECT_NAME}:latest

echo "✅ Image pushed to ${ACR_LOGIN_SERVER}/${PROJECT_NAME}:latest"

# ==========================================
# Step 3: Deploy Full Infrastructure
# ==========================================
echo "☁️  Step 3/3: Deploying Container App and full infrastructure..."
cd "$SCRIPT_DIR/.."

terraform apply \
  -var="environment=$ENVIRONMENT" \
  -var="openai_api_key=$OPENAI_API_KEY" \
  -auto-approve

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📊 Deployment Details:"
echo "🔐 Container Registry: $(terraform output -raw container_registry_url)"
echo "🚀 Container App URL: $(terraform output -raw container_app_url)"
echo "📦 Resource Group: $(terraform output -raw resource_group)"
