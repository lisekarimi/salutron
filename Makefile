# =====================================
# 🌱 Project & Environment Configuration
# =====================================
# Read from pyproject.toml using grep (works on all platforms)
PROJECT_NAME = $(shell python3 -c "import re; print(re.search('name = \"(.*)\"', open('pyproject.toml').read()).group(1))")
VERSION = $(shell python3 -c "import re; print(re.search('version = \"(.*)\"', open('pyproject.toml').read()).group(1))")
-include .env
export

# Docker configuration
IMAGE_NAME = $(PROJECT_NAME)
CONTAINER_NAME = $(PROJECT_NAME)-container
APP_PORT = 5000

# =====================================
# 🐋 Docker Commands (Development)
# =====================================
dev: ## Build and run development container with hot reload
	docker build --no-cache -t $(IMAGE_NAME):dev .
	docker run -d \
		--name $(CONTAINER_NAME)-dev \
		-p $(APP_PORT):$(APP_PORT) \
		-v $(PWD):/app \
		--env-file .env \
		$(IMAGE_NAME):dev
	@echo "🎯 Salutron running at http://localhost:$(APP_PORT)"
	@echo "🤖 OpenAI integration ready"

ls: ## List files inside the container
	docker run --rm $(IMAGE_NAME):dev ls -la /app

logs: ## Show container logs
	docker logs -f $(CONTAINER_NAME)-dev

stop: ## Stop dev container
	docker stop $(CONTAINER_NAME)-dev || true

clean: stop ## Stop and remove dev container and image
	docker rm $(CONTAINER_NAME)-dev || true
	docker rmi $(IMAGE_NAME):dev || true

restart: clean dev ## Restart dev container


# =====================================
# 🚀 AWS Deployment / Destroy via Terraform locally
# =====================================
# =====================================
# Prerequisites:
# Add these IAM policies to your AWS user:
# - AmazonEC2ContainerRegistryFullAccess
# - IAMFullAccess
# - AWSAppRunnerFullAccess
# - AmazonS3FullAccess
# - AmazonSNSFullAccess
# - CloudWatchFullAccess
# =====================================

# AWS Deployment
aws-deploy-dev: ## Deploy to AWS dev
	./terraform/aws/scripts/deploy.sh dev

aws-deploy-test: ## Deploy to AWS test
	./terraform/aws/scripts/deploy.sh test

aws-deploy-prod: ## Deploy to AWS prod
	./terraform/aws/scripts/deploy.sh prod


aws-destroy-dev: ## Destroy dev
	./terraform/aws/scripts/destroy.sh dev

aws-destroy-test: ## Destroy test
	./terraform/aws/scripts/destroy.sh test

aws-destroy-prod: ## Destroy prod
	./terraform/aws/scripts/destroy.sh prod


# =====================================
# 🚀 GCP Deployment / Destroy via Terraform locally
# =====================================

gcp-setup: ## One-time GCP project setup
	./terraform/gcp/scripts/setup.sh

# GCP Deployment
gcp-deploy-dev: ## Deploy to GCP dev
	./terraform/gcp/scripts/deploy.sh dev

gcp-deploy-test: ## Deploy to GCP test
	./terraform/gcp/scripts/deploy.sh test

gcp-deploy-prod: ## Deploy to GCP prod
	./terraform/gcp/scripts/deploy.sh prod

# GCP Destroy
gcp-destroy-dev: ## Destroy GCP dev
	./terraform/gcp/scripts/destroy.sh dev

gcp-destroy-test: ## Destroy GCP test
	./terraform/gcp/scripts/destroy.sh test

gcp-destroy-prod: ## Destroy GCP prod
	./terraform/gcp/scripts/destroy.sh prod


# =====================================
# 🚀 Azure Deployment / Destroy via Terraform locally
# =====================================

azure-setup: ## One-time Azure setup
	./terraform/azure/scripts/setup.sh


# Azure Deployment
azure-deploy-dev: ## Deploy to Azure dev
	./terraform/azure/scripts/deploy.sh dev

azure-deploy-test: ## Deploy to Azure test
	./terraform/azure/scripts/deploy.sh test

azure-deploy-prod: ## Deploy to Azure prod
	./terraform/azure/scripts/deploy.sh prod

# Azure Destroy
azure-destroy-dev: ## Destroy Azure dev
	./terraform/azure/scripts/destroy.sh dev

azure-destroy-test: ## Destroy Azure test
	./terraform/azure/scripts/destroy.sh test

azure-destroy-prod: ## Destroy Azure prod
	./terraform/azure/scripts/destroy.sh prod



# =====================================
# 🚀 GitHub Actions Setup
# =====================================

# =====================================
# AWS Prerequisites:
# Add these IAM policies to your AWS user:
# - AmazonDynamoDBFullAccess_v2
# - AmazonEC2ContainerRegistryFullAccess
# - IAMFullAccess
# - AWSAppRunnerFullAccess
# - AmazonS3FullAccess
# - AmazonSNSFullAccess
# - CloudWatchFullAccess
# =====================================

aws-setup-backend: ## Create S3 and DynamoDB for remote state (one-time)
	@echo "🔐 Creating remote state backend..."
	@cd terraform/ci-setup/aws && \
	terraform init -input=false && \
	terraform apply \
	  -target=aws_s3_bucket.terraform_state \
	  -target=aws_s3_bucket_versioning.terraform_state \
	  -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
	  -target=aws_s3_bucket_public_access_block.terraform_state \
	  -target=aws_dynamodb_table.terraform_locks

aws-setup-github-oidc: ## Setup GitHub OIDC for CI/CD (one-time)
	@echo "🔐 Setting up GitHub OIDC..."
	@cd terraform/ci-setup/aws && \
	terraform init -input=false && \
	terraform apply -auto-approve
	@echo ""
	@echo "✅ GitHub OIDC setup complete!"
	@cd terraform/ci-setup/aws && terraform output github_actions_role_arn


# =====================================
# GCP Prerequisites:
# - Authenticate with gcloud auth application-default login
# - Create/set the GCP project
# - Run make gcp-setup
# =====================================

gcp-setup-backend: ## Create GCS bucket for Terraform state (one-time)
	@echo "🔐 Creating GCP backend for Terraform state..."
	@cd terraform/ci-setup/gcp && \
	terraform init -input=false && \
	terraform apply \
	  -target=google_storage_bucket.terraform_state \
	  -auto-approve
	@echo "✅ GCP backend created successfully!"


gcp-setup-github-workload-identity: ## Setup GCP Workload Identity for GitHub Actions (one-time)
	@echo "🔐 Setting up GCP Workload Identity..."
	@cd terraform/ci-setup/gcp && \
	terraform init -input=false && \
	terraform apply -auto-approve
	@echo ""
	@echo "✅ Workload Identity setup complete!"
	@cd terraform/ci-setup/gcp && terraform output workload_identity_provider
	@cd terraform/ci-setup/gcp && terraform output service_account_email


# =====================================
# Azure Prerequisites:
# - Create/set the Azure subscription
# - Run make azure-setup
# =====================================

azure-setup-backend: ## Create Storage Account for Terraform state (one-time)
	@echo "🔐 Creating Azure backend for Terraform state..."
	@cd terraform/ci-setup/azure && \
	terraform init -input=false && \
	terraform apply -auto-approve
	@echo "✅ Azure backend created successfully!"


azure-setup-workload-identity: ## Setup Azure Workload Identity for GitHub Actions (one-time)
	@echo "🔐 Setting up Azure Workload Identity..."
	@cd terraform/ci-setup/azure && \
	terraform init -input=false && \
	terraform apply -auto-approve
	@echo ""
	@echo "✅ Workload Identity setup complete!"
	@cd terraform/ci-setup/azure && terraform output client_id
	@cd terraform/ci-setup/azure && terraform output tenant_id
	@cd terraform/ci-setup/azure && terraform output subscription_id


# =====================================
# Local Website
# =====================================
gh: ## Serve GitHub Pages locally
	@echo "🌐 Starting local server at http://localhost:8000"
	@echo "📁 Serving docs/ folder"
	@echo "Press Ctrl+C to stop"
	@cd docs && python3 -m http.server 8000








# =====================================
# 📚 Documentation & Help
# =====================================

help: ## Show this help message
	@echo "Available commands:"
	@echo ""
	@python3 -c "import re; lines=open('Makefile', encoding='utf-8').readlines(); targets=[re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$',l) for l in lines]; [print(f'  make {m.group(1):<20} {m.group(2)}') for m in targets if m]"


# =======================
# 🎯 PHONY Targets
# =======================

# Auto-generate PHONY targets (cross-platform)
.PHONY: $(shell python3 -c "import re; print(' '.join(re.findall(r'^([a-zA-Z_-]+):\s*.*?##', open('Makefile', encoding='utf-8').read(), re.MULTILINE)))")

# Test the PHONY generation
# test-phony:
# 	@echo "$(shell python3 -c "import re; print(' '.join(sorted(set(re.findall(r'^([a-zA-Z0-9_-]+):', open('Makefile', encoding='utf-8').read(), re.MULTILINE)))))")"
