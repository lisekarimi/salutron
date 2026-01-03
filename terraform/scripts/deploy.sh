#!/bin/bash

# terraform/scripts/deploy.sh
# This script is used to deploy the application to AWS App Runner

set -e

ENVIRONMENT=${1:-dev}

if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
  echo "Error: Environment must be dev, test, or prod"
  exit 1
fi

echo "🚀 Starting full deployment to ${ENVIRONMENT}..."

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

# ==========================================
# Step 1: Create ECR Repository
# ==========================================
echo "📦 Step 1/3: Creating ECR repository..."
cd terraform
terraform init -input=false

if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
  terraform workspace new "$ENVIRONMENT"
else
  terraform workspace select "$ENVIRONMENT"
fi

terraform apply \
  -target=aws_ecr_repository.app_repo \
  -var="environment=$ENVIRONMENT" \
  -var="openai_api_key=$OPENAI_API_KEY" \
  -auto-approve
cd ..

# ==========================================
# Step 2: Build and Push Docker Image
# ==========================================
echo "🐳 Step 2/3: Building and pushing Docker image..."

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT_NAME=$(python3 -c "import re; print(re.search('name = \"(.*)\"', open('pyproject.toml').read()).group(1))")
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT_NAME}-${ENVIRONMENT}-repo"

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

# Build, tag, and push
docker build -t ${PROJECT_NAME}:latest .
docker tag ${PROJECT_NAME}:latest ${ECR_URI}:latest
docker push ${ECR_URI}:latest

echo "✅ Image pushed to ${ECR_URI}:latest"

# ==========================================
# Step 3: Deploy Full Infrastructure
# ==========================================
echo "☁️  Step 3/3: Deploying App Runner and full infrastructure..."
cd terraform
terraform apply \
  -var="environment=$ENVIRONMENT" \
  -var="openai_api_key=$OPENAI_API_KEY"

echo ""
echo "🎉 Deployment complete!"
echo "📊 Check outputs above for App Runner URL"
