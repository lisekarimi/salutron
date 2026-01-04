#!/bin/bash

# terraform/aws/scripts/deploy.sh
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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

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
    -target=aws_ecr_repository.app_repo \
    -var-file=prod.tfvars \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY" \
    -auto-approve
else
  terraform apply \
    -target=aws_ecr_repository.app_repo \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY" \
    -auto-approve
fi

cd "$PROJECT_ROOT"

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
cd "$SCRIPT_DIR/.."

# Use prod.tfvars for production
if [ "$ENVIRONMENT" = "prod" ]; then
  terraform apply \
    -var-file=prod.tfvars \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY" \
    -auto-approve
else
  terraform apply \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY" \
    -auto-approve
fi

echo ""
echo "🎉 Deployment complete!"
echo "📊 Check outputs above for App Runner URL"

# Show custom domain instructions for prod
if [ "$ENVIRONMENT" = "prod" ]; then
  CUSTOM_DOMAIN=$(grep 'custom_domain' "$SCRIPT_DIR/../prod.tfvars" | cut -d'"' -f2)
  echo ""
  echo "🌐 Custom Domain Setup Required:"
  echo "1. Run: cd terraform/aws && terraform output custom_domain_dns_records"
  echo "2. Add the DNS records to Cloudflare"
  echo "3. Wait 5-10 minutes for validation"
  echo "4. Your app will be available at: ${CUSTOM_DOMAIN}"
fi
