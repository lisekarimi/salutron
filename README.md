# Salutron 👋

A production-ready DevOps project demonstrating enterprise-level Infrastructure as Code practices with Terraform, Docker, and AWS.

> **What makes this special?** Deploy complete multi-environment infrastructure with a single command. Full automation from build to production.

## 🎯 Project Goals

This project demonstrates:
- ✅ Multi-environment infrastructure (dev/test/prod)
- ✅ One-command deployment and teardown
- ✅ Enterprise-level automation with Bash + Makefiles
- ✅ Secure secret management
- ✅ Production-ready DevOps workflow

## 🚀 Key Features

### Multi-Environment Infrastructure
- 3 isolated environments using Terraform workspaces
- Single codebase for all environments
- Independent state management per environment

### One-Command Automation
```bash
make deploy-dev   # Build → Push → Deploy
make deploy-prod  # Deploy to production
make destroy-dev  # Complete teardown
```

### Enterprise Practices
- Automated deployment orchestration
- Secure environment variable management
- Docker image optimization with UV
- Zero manual AWS Console interaction

### Production-Ready Configuration
- Custom domain support (prod environment)
- Environment-specific scaling (dev: 1-2, prod: 2-5 instances)
- Production configuration via `prod.tfvars`
- Automatic SSL/TLS certificate management

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Terraform** | Infrastructure as Code with workspace management |
| **Docker** | Containerization with optimized builds |
| **AWS App Runner** | Serverless container deployment |
| **AWS ECR** | Container registry |
| **OpenAI GPT-4** | AI-powered greetings |
| **Bash + Make** | Deployment automation |

## 📋 Prerequisites

**Skills assumed:**
- Familiarity with Docker
- Basic AWS knowledge
- AWS CLI configured
- Understanding of Makefiles

**Tools required:**
- Docker Desktop
- Terraform >= 1.0
- AWS CLI v2
- Python 3.11+
- Make

## 🔐 AWS Setup

### 1. Create IAM User for Terraform

Create a dedicated IAM user (e.g., `terraform_user`) with these policies:
```
✅ AmazonEC2ContainerRegistryFullAccess  - Manage Docker images in ECR
✅ IAMFullAccess                          - Create IAM roles for App Runner
✅ AWSAppRunnerFullAccess                 - Deploy App Runner services
✅ AmazonS3FullAccess                     - Manage S3 buckets
```

### 2. Configure AWS CLI
```bash
aws configure
# Enter your terraform_user credentials
```

## 🚀 Quick Start

### 1. Clone & Setup
```bash
git clone https://github.com/lisekarimi/salutron.git
cd salutron
```

### 2. Configure Environment
```bash
# Copy example env file
cp .env.example .env

# Edit .env and add your OpenAI API key
OPENAI_API_KEY=sk-your-key-here
```

### 3. Deploy!
```bash
# Deploy to development
make deploy-dev

# Deploy to production
make deploy-prod

# Destroy environment
make destroy-dev
```

That's it! The entire infrastructure is built and deployed automatically.

## 🌐 Custom Domain Setup (Production)

Production deployments support custom domains:

1. **Update `terraform/aws/prod.tfvars`:**
   ```hcl
   custom_domain = "your-subdomain.yourdomain.com"
   ```

2. **Deploy to production:**
   ```bash
   make deploy-prod
   ```

3. **Get DNS records:**
   ```bash
   cd terraform/aws
   terraform output custom_domain_dns_records
   ```

4. **Add CNAME records to your DNS provider** (Cloudflare, Route53, etc.)

5. **Wait 5-10 minutes** for SSL certificate validation

Your app will be available at your custom domain with automatic HTTPS!

## 🎓 What You'll Learn

### Infrastructure as Code
- Terraform workspace management
- Multi-environment deployments
- Resource dependencies
- State management

### Containerization
- Docker multi-stage builds
- ECR repository management
- Image optimization
- Security best practices

### AWS Services
- App Runner serverless containers
- ECR container registry
- S3 object storage
- IAM roles and policies

### DevOps Automation
- Bash scripting for orchestration
- Makefile automation
- Secret management
- CI/CD workflows
- Custom domain configuration with SSL
- Environment-specific resource scaling

## 📄 License

MIT License - feel free to use this project for learning!

## 👤 Author

**Lise Karimi**
- Portfolio: [lisekarimi.com](https://lisekarimi.com)
- GitHub: [@lisekarimi](https://github.com/lisekarimi)

---

Built with ❤️ while learning DevOps

**⭐ Star this repo if it helped you learn Terraform and AWS!**
