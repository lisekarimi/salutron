# terraform/main.tf - this file contains the main configuration for the project

# ==========================================
# Provider Configuration
# ==========================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==========================================
# Data Sources
# ==========================================
data "aws_caller_identity" "current" {}

# ==========================================
# Local Variables
# ==========================================
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ==========================================
# S3 Resources
# ==========================================
resource "aws_s3_bucket" "app_bucket" {
  bucket = "${local.name_prefix}-bucket-${data.aws_caller_identity.current.account_id}"
  tags   = local.common_tags
}

# ==========================================
# ECR Resources
# ==========================================
resource "aws_ecr_repository" "app_repo" {
  name                 = "${local.name_prefix}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "app_repo_policy" {
  repository = aws_ecr_repository.app_repo.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ==========================================
# IAM Role for App Runner
# ==========================================
resource "aws_iam_role" "apprunner_role" {
  name = "${local.name_prefix}-apprunner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr" {
  role       = aws_iam_role.apprunner_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# ==========================================
# App Runner Auto-Scaling Configuration
# ==========================================
resource "aws_apprunner_auto_scaling_configuration_version" "app_scaling" {
  auto_scaling_configuration_name = "${local.name_prefix}-scaling"

  min_size = 1
  max_size = 2

  tags = local.common_tags
}

# ==========================================
# App Runner Service
# ==========================================
resource "aws_apprunner_service" "app" {
  service_name = "${local.name_prefix}-service"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_role.arn
    }

    image_repository {
      image_identifier      = "${aws_ecr_repository.app_repo.repository_url}:latest"
      image_repository_type = "ECR"

      image_configuration {
        port = "5000"

        runtime_environment_variables = {
          OPENAI_API_KEY = var.openai_api_key
        }
      }
    }

    auto_deployments_enabled = false
  }

  instance_configuration {
    cpu    = "1024"  # 1 vCPU
    memory = "2048"  # 2 GB
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.app_scaling.arn

  health_check_configuration {
    protocol = "HTTP"
    path     = "/"
  }

  tags = local.common_tags
}
