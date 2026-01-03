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
# 🚀 AWS Deployment / Destroy via Terraform
# =====================================
# =====================================
# Prerequisites:
# Add these IAM policies to your AWS user:
# - AmazonEC2ContainerRegistryFullAccess
# - IAMFullAccess
# - AWSAppRunnerFullAccess
# - AmazonS3FullAccess
# =====================================

deploy-dev: ## Deploy to AWS dev
	./terraform/scripts/deploy.sh dev

deploy-test: ## Deploy to AWS test
	./terraform/scripts/deploy.sh test

deploy-prod: ## Deploy to AWS prod
	./terraform/scripts/deploy.sh prod


destroy-dev: ## Destroy dev
	./terraform/scripts/destroy.sh dev

destroy-test: ## Destroy test
	./terraform/scripts/destroy.sh test

destroy-prod: ## Destroy prod
	./terraform/scripts/destroy.sh prod


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
