# terraform/ci-setup/gcp/github-workload-identity.tf

# One-time setup for GitHub OIDC and CI/CD permissions
# Run once, then delete this file

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  default     = "lisekarimi/salutron" # adjust this to your repository
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "salutron"
}

# ==========================================
# Enable required APIs
# ==========================================
resource "google_project_service" "iam" {
  project            = var.project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iamcredentials" {
  project            = var.project_id
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sts" {
  project            = var.project_id
  service            = "sts.googleapis.com"
  disable_on_destroy = false
}

# ==========================================
# Workload Identity Pool
# ==========================================
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions"

  depends_on = [google_project_service.iam]
}

# ==========================================
# Workload Identity Providers - One per environment
# ==========================================
resource "google_iam_workload_identity_pool_provider" "github_dev" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-dev"
  display_name                       = "GitHub Dev Provider"
  description                        = "OIDC provider for GitHub Actions - Dev"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}' && assertion.sub.startsWith('repo:${var.github_repository}:environment:dev')"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_iam_workload_identity_pool_provider" "github_test" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-test"
  display_name                       = "GitHub Test Provider"
  description                        = "OIDC provider for GitHub Actions - Test"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}' && assertion.sub.startsWith('repo:${var.github_repository}:environment:test')"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_iam_workload_identity_pool_provider" "github_prod" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-prod"
  display_name                       = "GitHub Prod Provider"
  description                        = "OIDC provider for GitHub Actions - Prod"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}' && assertion.sub.startsWith('repo:${var.github_repository}:environment:prod')"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ==========================================
# Service Account
# ==========================================
resource "google_service_account" "github_actions" {
  project      = var.project_id
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions Service Account"
  description  = "Service account for GitHub Actions deployments"
}

# ==========================================
# Service Account Permissions
# ==========================================
resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset([
    "roles/run.admin",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/iam.serviceAccountUser",
    "roles/monitoring.admin",
    "roles/compute.viewer",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.securityAdmin",
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# ==========================================
# Workload Identity Bindings - One per environment
# ==========================================
resource "google_service_account_iam_member" "github_actions_workload_identity_dev" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"

  condition {
    title       = "dev-environment"
    description = "Allow dev environment only"
    expression  = "assertion.sub.startsWith('repo:${var.github_repository}:environment:dev')"
  }
}

resource "google_service_account_iam_member" "github_actions_workload_identity_test" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"

  condition {
    title       = "test-environment"
    description = "Allow test environment only"
    expression  = "assertion.sub.startsWith('repo:${var.github_repository}:environment:test')"
  }
}

resource "google_service_account_iam_member" "github_actions_workload_identity_prod" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"

  condition {
    title       = "prod-environment"
    description = "Allow prod environment only"
    expression  = "assertion.sub.startsWith('repo:${var.github_repository}:environment:prod')"
  }
}

# ==========================================
# Outputs
# ==========================================
output "workload_identity_provider_dev" {
  value       = google_iam_workload_identity_pool_provider.github_dev.name
  description = "Workload Identity Provider for dev"
}

output "workload_identity_provider_test" {
  value       = google_iam_workload_identity_pool_provider.github_test.name
  description = "Workload Identity Provider for test"
}

output "workload_identity_provider_prod" {
  value       = google_iam_workload_identity_pool_provider.github_prod.name
  description = "Workload Identity Provider for prod"
}

output "service_account_email" {
  value       = google_service_account.github_actions.email
  description = "Service Account email for GitHub Actions"
}
