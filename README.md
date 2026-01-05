# Salutron 👋

Production-ready multi-cloud Infrastructure as Code demonstrating enterprise DevOps practices with Terraform, Docker, AWS, and GCP.

Learn more: [salutron.lisekarimi.com](https://salutron.lisekarimi.com)

## 🎯 Overview

Multi-environment (dev/test/prod) infrastructure with automated CI/CD pipelines, demonstrating:
- Single-command deployment/teardown across AWS and GCP
- OIDC/Workload Identity Federation for secure GitHub Actions
- Remote state management with workspace isolation
- Docker containerization with optimized builds

## 📋 Prerequisites

**Required:**
- Docker, Terraform ≥1.0, AWS CLI v2, gcloud CLI, Python 3.11+, Make
- AWS account with IAM user configured
- GCP project with billing enabled
- GitHub repository with Actions enabled

**Skills:**
- Terraform, Docker, Bash scripting, CI/CD concepts

## 🛠️ Tech Stack

| Component | AWS | GCP |
|-----------|-----|-----|
| Compute | App Runner | Cloud Run |
| Registry | ECR | Artifact Registry |
| Storage | S3 | Cloud Storage |
| Auth | IAM + OIDC | Service Accounts + Workload Identity |
| State | S3 + DynamoDB | Cloud Storage |


## 🚀 Deployment Guide

### AWS Deployment

#### Local Deployment

**1. Create IAM User**
Create `terraform_user` with these policies:
-  AmazonDynamoDBFullAccess_v2
- `AmazonEC2ContainerRegistryFullAccess`
- `IAMFullAccess`
- `AWSAppRunnerFullAccess`
- `AmazonS3FullAccess`
# - AmazonDynamoDBFullAccess_v2
# - AmazonEC2ContainerRegistryFullAccess
# - IAMFullAccess
# - AWSAppRunnerFullAccess
# - AmazonS3FullAccess
# - AmazonSNSFullAccess
# - CloudWatchFullAccess

**2. Configure AWS CLI**
```bash
aws configure
# Enter terraform_user credentials
```

**3. Setup Remote State Backend (One-Time)**
```bash
make aws-setup-backend
```

**4. Deploy to Environment**
```bash
make aws-deploy-dev   # Development
make aws-deploy-test  # Testing
make aws-deploy-prod  # Production
```

**5. Destroy Environment**
```bash
make aws-destroy-dev
```

#### GitHub Actions CI/CD Setup

**1. Setup OIDC Authentication**
```bash
make aws-setup-github-oidc
# Save the output: github_actions_role_arn
```

**2. Add GitHub Secrets**
Go to GitHub repo → Settings → Secrets and variables → Actions:
- `AWS_ROLE_ARN`: `arn:aws:iam::YOUR_ACCOUNT:role/github-actions-salutron-deploy`
- `DEFAULT_AWS_REGION`: `us-east-1`
- `AWS_ACCOUNT_ID`: Your 12-digit AWS account ID
- `OPENAI_API_KEY`: Your OpenAI API key

**3. Deploy via GitHub Actions**
- Go to Actions tab → "Deploy Salutron"
- Click "Run workflow"
- Select environment (dev/test/prod)

**Why OIDC Instead of Access Keys?**

```
Traditional Access Keys ❌          OIDC (Recommended) ✅
├─ Permanent credentials           ├─ Temporary tokens (~1 hour)
├─ Manual rotation needed          ├─ Auto-rotates each run
├─ Security risk if leaked         ├─ No credentials stored
└─ Hard to audit                   └─ Full audit trail
```

**How OIDC Works:**
```
┌─────────────┐                    ┌─────────────┐
│   GitHub    │ 1. JWT token      │     AWS     │
│   Actions   ├──────────────────>│   verifies  │
│             │ 2. Temp creds     │   identity  │
│             │<──────────────────┤             │
└─────────────┘                    └─────────────┘
```

### GCP Deployment

#### Local Deployment

**1. Initial GCP Setup**
```bash
make gcp-setup
# Authenticates and enables required APIs
```

**2. Setup Remote State Backend (One-Time)**
```bash
make gcp-setup-backend
```

**3. Deploy to Environment**
```bash
make gcp-deploy-dev   # Development
make gcp-deploy-test  # Testing
make gcp-deploy-prod  # Production
```

**4. Destroy Environment**
```bash
make gcp-destroy-dev
```

#### GitHub Actions CI/CD Setup

**1. Setup Workload Identity Federation**
```bash
make gcp-setup-workload-identity
# Save both outputs:
# - workload_identity_provider
# - service_account_email
```

**2. Add GitHub Secrets**
Go to GitHub repo → Settings → Secrets and variables → Actions:
- `GCP_PROJECT_ID`: `salutron`
- `GCP_WORKLOAD_IDENTITY_PROVIDER`: `projects/280220662544/locations/global/...`
- `GCP_SERVICE_ACCOUNT`: `github-actions-sa@salutron.iam.gserviceaccount.com`
- `GCP_REGION`: `us-central1`
- `OPENAI_API_KEY`: Your OpenAI API key

**3. Deploy via GitHub Actions**
- Go to Actions tab → "Deploy Salutron to GCP"
- Click "Run workflow"
- Select environment (dev/test/prod)

**GCP Workload Identity = AWS OIDC**
Same concept, different name. No long-lived service account keys needed!

## 🌐 AWS vs GCP Comparison

| Feature | AWS | GCP |
|---------|-----|-----|
| **Container Service** | App Runner | Cloud Run |
| **Container Registry** | ECR | Artifact Registry |
| **Object Storage** | S3 | Cloud Storage |
| **Authentication** | IAM Roles | Service Accounts |
| **CI/CD Auth** | OIDC | Workload Identity Federation |
| **State Storage** | S3 + DynamoDB | Cloud Storage (GCS) |



## 📄 License

MIT License - feel free to use this project for learning!

## 👤 Author

**Lise Karimi**
- Portfolio: [lisekarimi.com](https://lisekarimi.com)
- GitHub: [@lisekarimi](https://github.com/lisekarimi)

Built with ❤️ while learning DevOps

**⭐ Star this repo if it helped you learn Terraform and AWS/GCP!**


Azure Account (Your Email)
  └── Subscription (e.g., "Azure for Students")
      └── Resource Group (e.g., "cyber-analyzer-rg")
          └── Resources (Container Apps, Registry, etc.)

            Install Azure cli
            az --version
            az login
            az account list --output table
            az group list --output table
