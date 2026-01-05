#!/bin/bash

# terraform/gcp/scripts/deploy.sh
# This script deploys the application to GCP Cloud Run

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
# Step 1: Create Artifact Registry Repository
# ==========================================
echo "📦 Step 1/3: Creating Artifact Registry repository..."
cd "$SCRIPT_DIR/.."
terraform init -input=false

if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
  terraform workspace new "$ENVIRONMENT"
else
  terraform workspace select "$ENVIRONMENT"
fi

# Use prod.tfvars for production
if [ "$ENVIRONMENT" = "prod" ]; then
  terraform apply \
    -target=google_artifact_registry_repository.app_repo \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY" \
    -var-file=prod.tfvars \
    -auto-approve
else
  terraform apply \
    -target=google_artifact_registry_repository.app_repo \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY" \
    -auto-approve
fi

cd "$PROJECT_ROOT"

# ==========================================
# Step 2: Build and Push Docker Image
# ==========================================
echo "🐳 Step 2/3: Building and pushing Docker image..."

# Get project details
PROJECT_ID=$(cd "$SCRIPT_DIR/.." && terraform output -raw project_id 2>/dev/null || grep 'project_id' terraform.tfvars | cut -d'"' -f2)
PROJECT_NAME=$(python3 -c "import re; print(re.search('name = \"(.*)\"', open('pyproject.toml').read()).group(1))")
GCP_REGION="us-central1"
ARTIFACT_REGISTRY_URL="${GCP_REGION}-docker.pkg.dev/${PROJECT_ID}/${PROJECT_NAME}-${ENVIRONMENT}-repo"

# Configure Docker authentication for Artifact Registry
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://${GCP_REGION}-docker.pkg.dev

# Build, tag, and push
docker build -t ${PROJECT_NAME}:latest .
docker tag ${PROJECT_NAME}:latest ${ARTIFACT_REGISTRY_URL}/${PROJECT_NAME}:latest
docker push ${ARTIFACT_REGISTRY_URL}/${PROJECT_NAME}:latest

echo "✅ Image pushed to ${ARTIFACT_REGISTRY_URL}/${PROJECT_NAME}:latest"

# ==========================================
# Step 3: Deploy Full Infrastructure
# ==========================================
echo "☁️  Step 3/3: Deploying Cloud Run and full infrastructure..."
cd "$SCRIPT_DIR/.."

# Use prod.tfvars for production
if [ "$ENVIRONMENT" = "prod" ]; then
  terraform apply \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY" \
    -var-file=prod.tfvars \
    -auto-approve
else
  terraform apply \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY" \
    -auto-approve
fi

echo ""
echo "🎉 Deployment complete!"
echo "📊 Check outputs above for Cloud Run URL"
echo "📊 Check outputs above for Cloud Run URL"

# ==========================================
# Step 4: Wait for Domain Mapping (prod only)
# ==========================================
if [ "$ENVIRONMENT" = "prod" ]; then
  CUSTOM_DOMAIN=$(grep 'custom_domain' prod.tfvars 2>/dev/null | cut -d'"' -f2)
  if [ ! -z "$CUSTOM_DOMAIN" ]; then
    echo ""
    echo "⏳ Waiting for SSL certificate provisioning..."
    echo "This typically takes 5-15 minutes..."

    # Check domain mapping status
    for i in {1..30}; do
      STATUS=$(gcloud run domain-mappings describe "$CUSTOM_DOMAIN" \
        --region="$GCP_REGION" \
        --project="$PROJECT_ID" \
        --format="value(status.conditions[0].status)" 2>/dev/null || echo "Unknown")

      if [ "$STATUS" = "True" ]; then
        echo "✅ SSL certificate is ready!"
        break
      fi

      echo "Still provisioning... (${i}/30)"
      sleep 30
    done
  fi
fi
