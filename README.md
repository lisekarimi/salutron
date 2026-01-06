# Salutron 👋

Production-ready multi-cloud Infrastructure as Code demonstrating enterprise DevOps practices with Terraform, Docker, AWS, GCP, and Azure.

![Workflow](https://github.com/lisekarimi/salutron/blob/main/assets/wrokflow.png?raw=true)

Learn more: [salutron.lisekarimi.com](https://salutron.lisekarimi.com)

## 🎯 Overview

Multi-environment (dev/test/prod) infrastructure with automated CI/CD pipelines, demonstrating:
- Single-command deployment/teardown across **AWS, GCP, and Azure**
- OIDC/Workload Identity Federation for secure GitHub Actions
- Remote state management with workspace isolation
- Docker containerization with optimized builds

---

## 📋 Prerequisites

**Required:**
- Docker, Terraform ≥1.0, AWS CLI v2, gcloud CLI, **Azure CLI**, Python 3.11+, Make
- AWS account with IAM user configured
- GCP project with billing enabled
- **Azure subscription with resource group**
- GitHub repository with Actions enabled

**Skills:**
- Terraform, Docker, Bash scripting, CI/CD concepts

---

## 🛠️ Tech Stack

| Component | AWS | GCP | Azure |
|-----------|-----|-----|-------|
| Compute | App Runner | Cloud Run | Container Apps |
| Registry | ECR | Artifact Registry | ACR |
| Storage | S3 | Cloud Storage | Blob Storage |
| Auth | IAM + OIDC | Service Accounts + Workload Identity | Service Principal + Workload Identity |
| State | S3 + DynamoDB | Cloud Storage | Blob Storage |

---

## 🚀 Deployment Guide

### AWS Deployment

#### 💻 Local Deployment

**1️⃣ Create IAM User**
Create `terraform_user` with these policies:
- `AmazonEC2ContainerRegistryFullAccess`
- `IAMFullAccess`
- `AWSAppRunnerFullAccess`
- `AmazonS3FullAccess`
- `AmazonSNSFullAccess`
- `CloudWatchFullAccess`
- `AmazonDynamoDBFullAccess`

**2️⃣ Configure AWS CLI**
```bash
aws configure
# Enter terraform_user credentials
```

**3️⃣ Setup Remote State Backend (One-Time)**
```bash
make aws-setup-backend
```

**4️⃣ Update Terraform Variables**
> **⚠️ IMPORTANT:** Before deploying, update `terraform/aws/terraform.tfvars` and environment-specific files (e.g., `prod.tfvars`) with your own data (project name, region, custom domain, etc.).

**5️⃣ Deploy to Environment**
```bash
make aws-deploy-dev   # Development
make aws-deploy-test  # Testing
make aws-deploy-prod  # Production
```

**6️⃣ Destroy Environment**
```bash
make aws-destroy-dev
```

#### ⚙️ GitHub Actions CI/CD Setup

> **⚠️ IMPORTANT:** Before proceeding, make sure to adjust the repository name in `terraform/ci-setup/aws/github-oidc.tf` (variable `github_repository`) to match your own repository in the format `owner/repo`.

**1️⃣ Setup OIDC Authentication**
```bash
make aws-setup-github-oidc
# Save the output: github_actions_role_arn
```

**2️⃣ Add GitHub Secrets**
Go to GitHub repo → Settings → Secrets and variables → Actions:
- `AWS_ROLE_ARN`: `arn:aws:iam::YOUR_ACCOUNT:role/github-actions-salutron-deploy`
- `DEFAULT_AWS_REGION`: `us-east-1`
- `AWS_ACCOUNT_ID`: Your 12-digit AWS account ID
- `OPENAI_API_KEY`: Your OpenAI API key

**3️⃣ Deploy via GitHub Actions**
- Go to Actions tab → "Deploy Salutron"
- Click "Run workflow"
- Select environment (dev/test/prod)

**🔐 Why OIDC Instead of Access Keys?**

```
Traditional Access Keys ❌          OIDC (Recommended) ✅
├─ Permanent credentials           ├─ Temporary tokens (~1 hour)
├─ Manual rotation needed          ├─ Auto-rotates each run
├─ Security risk if leaked         ├─ No credentials stored
└─ Hard to audit                   └─ Full audit trail
```

**🔄 How OIDC Works:**
```
┌─────────────┐                    ┌─────────────┐
│   GitHub    │ 1. JWT token      │     AWS     │
│   Actions   ├──────────────────>│   verifies  │
│             │ 2. Temp creds     │   identity  │
│             │<──────────────────┤             │
└─────────────┘                    └─────────────┘
```

---

### GCP Deployment

#### 💻 Local Deployment

**1️⃣ Initial GCP Setup**
```bash
make gcp-setup
# Authenticates and enables required APIs
```

**2️⃣ Setup Remote State Backend (One-Time)**
```bash
make gcp-setup-backend
```

**3️⃣ Update Terraform Variables**
> **⚠️ IMPORTANT:** Before deploying, update `terraform/gcp/terraform.tfvars` and environment-specific files with your own data (project ID, project name, region, etc.).

**4️⃣ Deploy to Environment**
```bash
make gcp-deploy-dev   # Development
make gcp-deploy-test  # Testing
make gcp-deploy-prod  # Production
```

**4️⃣ Destroy Environment**
```bash
make gcp-destroy-dev
```

#### ⚙️ GitHub Actions CI/CD Setup

> **⚠️ IMPORTANT:** Before proceeding, make sure to adjust the repository name in `terraform/ci-setup/gcp/github-workload-identity.tf` (variable `github_repository`) to match your own repository in the format `owner/repo`.

**1️⃣ Setup Workload Identity Federation**
```bash
make gcp-setup-workload-identity
# Save both outputs:
# - workload_identity_provider
# - service_account_email
```

**2️⃣ Add GitHub Secrets**
Go to GitHub repo → Settings → Secrets and variables → Actions:
- `GCP_PROJECT_ID`: `salutron`
- `GCP_WORKLOAD_IDENTITY_PROVIDER`: `projects/280220662544/locations/global/...`
- `GCP_SERVICE_ACCOUNT`: `github-actions-sa@salutron.iam.gserviceaccount.com`
- `GCP_REGION`: `us-central1`
- `OPENAI_API_KEY`: Your OpenAI API key

**3️⃣ Deploy via GitHub Actions**
- Go to Actions tab → "Deploy Salutron to GCP"
- Click "Run workflow"
- Select environment (dev/test/prod)

> **💡 GCP Workload Identity = AWS OIDC**
> Same concept, different name. No long-lived service account keys needed!

---

### Azure Deployment

#### 💻 Local Deployment

**1️⃣ Install Azure CLI**
```bash
az --version
az login
```

**2️⃣ Initial Azure Setup**
```bash
make azure-setup
# Registers required resource providers
```

**3️⃣ Setup Remote State Backend (One-Time)**
```bash
make azure-setup-backend
```

**4️⃣ Update Terraform Variables**
> **⚠️ IMPORTANT:** Before deploying, update `terraform/azure/terraform.tfvars` and environment-specific files with your own data (project name, region, resource group name, etc.).

**5️⃣ Deploy to Environment**
```bash
make azure-deploy-dev   # Development
make azure-deploy-test  # Testing
make azure-deploy-prod  # Production
```

**6️⃣ Destroy Environment**
```bash
make azure-destroy-dev
```

#### ⚙️ GitHub Actions CI/CD Setup

> **⚠️ IMPORTANT:** Before proceeding, make sure to adjust the repository name in `terraform/ci-setup/azure/github-workload-identity.tf` (variable `github_repository`) to match your own repository in the format `owner/repo`.

**1️⃣ Setup Workload Identity Federation**
```bash
make azure-setup-workload-identity
# Save the outputs: client_id, tenant_id, subscription_id
```

**2️⃣ Add GitHub Secrets**
- `AZURE_CLIENT_ID`: Service principal client ID
- `AZURE_TENANT_ID`: Azure tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
- `AZURE_RESOURCE_GROUP`: `salutron-rg`
- `AZURE_REGION`: `francecentral`
- `OPENAI_API_KEY`: Your OpenAI API key

**3️⃣ Deploy via GitHub Actions**
- Actions → "Deploy Salutron to Azure"
- Click "Run workflow"
- Select environment

---

## 🌐 Multi-Cloud Comparison

| Feature | AWS | GCP | Azure |
|---------|-----|-----|-------|
| **Container Service** | App Runner | Cloud Run | Container Apps |
| **Container Registry** | ECR | Artifact Registry | ACR (Azure Container Registry) |
| **Object Storage** | S3 | Cloud Storage | Blob Storage |
| **Authentication** | IAM Roles | Service Accounts | Service Principals |
| **CI/CD Auth** | OIDC | Workload Identity | Workload Identity Federation |
| **State Storage** | S3 + DynamoDB | Cloud Storage (built-in locking) | Blob Storage + Container |
| **Min Instances** | 1 | 0 (scale to zero) | 1 (with ingress) |

---

## 🤔 Local vs GitHub Actions?

| Scenario | Use | Why |
|----------|-----|-----|
| **Learning/Testing** | Local | Fast iterations, immediate feedback |
| **Portfolio Projects** | Both | Shows CI/CD skills + practical knowledge |
| **Team Projects** | GitHub Actions | Consistent deployments, no "works on my machine" |
| **Production** | GitHub Actions | Audit trail, approvals, automated |

**This Project:** Implements both methods to demonstrate enterprise deployment strategies.

**Hybrid Pattern:**
```
Local: Dev testing (make aws-deploy-dev)
GitHub Actions: Test/Prod (automated + protected)
```

---

## 📄 License

MIT License - feel free to use this project for learning!

## 👤 Author

**Lise Karimi**
- Portfolio: [lisekarimi.com](https://lisekarimi.com)
- GitHub: [@lisekarimi](https://github.com/lisekarimi)

Built with ❤️ while learning DevOps

**⭐ Star this repo if it helped you learn Terraform and AWS/GCP/Azure!**
