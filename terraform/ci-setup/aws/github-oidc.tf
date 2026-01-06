# terraform/ci-setup/aws/github-oidc.tf

# One-time setup for GitHub OIDC and CI/CD permissions
# Run once, then delete this file

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  default     = "lisekarimi/salutron" # adjust this to your repository
}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-salutron-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Allow all environments (dev, test, prod)
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_repository}:environment:dev",
            "repo:${var.github_repository}:environment:test",
            "repo:${var.github_repository}:environment:prod"
          ]
        }
      }
    }]
  })

  tags = {
    Name       = "GitHub Actions Deploy Role"
    Repository = var.github_repository
    ManagedBy  = "terraform"
  }
}

# ==========================================
# Backend Access Policies
# ==========================================
resource "aws_iam_role_policy" "github_terraform_backend" {
  name = "github-actions-terraform-backend"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::salutron-terraform-state-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::salutron-terraform-state-${data.aws_caller_identity.current.account_id}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/salutron-terraform-locks"
      }
    ]
  })
}

# ==========================================
# Application Deployment Policies
# ==========================================
resource "aws_iam_role_policy_attachment" "github_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_apprunner" {
  policy_arn = "arn:aws:iam::aws:policy/AWSAppRunnerFullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_sns" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_cloudwatch" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_iam_read" {
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  role       = aws_iam_role.github_actions.name
}

# IAM Management
resource "aws_iam_role_policy" "github_iam_management" {
  name = "github-actions-iam-management"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:UpdateAssumeRolePolicy",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN of the IAM role for GitHub Actions"
}

output "backend_permissions_summary" {
  value = {
    s3_bucket      = "salutron-terraform-state-${data.aws_caller_identity.current.account_id}"
    dynamodb_table = "salutron-terraform-locks"
    permissions    = "Read/Write access to Terraform state backend"
  }
  description = "Summary of backend permissions granted"
}
