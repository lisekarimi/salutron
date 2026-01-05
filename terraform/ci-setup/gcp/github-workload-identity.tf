# terraform/ci-setup/gcp/github-workload-identity.tf

# One-time setup for GitHub OIDC and CI/CD permissions
# Run once, then delete this file

# ==========================================
# Variables
# ==========================================

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  default     = "lisekarimi/salutron"
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "salutron"
}

# ==========================================
# Enable required APIs
# ==========================================

# IAM API
resource "google_project_service" "iam" {
  project = var.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

# IAMCredentials API
resource "google_project_service" "iamcredentials" {
  project = var.project_id
  service = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

# STS API
resource "google_project_service" "sts" {
  project = var.project_id
  service = "sts.googleapis.com"
  disable_on_destroy = false
}


# ==========================================
# Create Workload Identity
# ==========================================

# Create Workload Identity Pool
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions"

  depends_on = [google_project_service.iam]
}

# Create Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  description                        = "OIDC provider for GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ==========================================
# Create Service Account for GitHub Actions
# ==========================================

resource "google_service_account" "github_actions" {
  project      = var.project_id
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions Service Account"
  description  = "Service account for GitHub Actions deployments"
}


# ==========================================
# Grant permissions to the service account
# ==========================================

resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset([
    "roles/run.admin",                    # Cloud Run
    "roles/artifactregistry.admin",       # Artifact Registry
    "roles/storage.admin",                # Cloud Storage
    "roles/iam.serviceAccountUser",       # Service Account usage
    "roles/monitoring.admin",             # Monitoring/Alerts
    "roles/compute.viewer",               # Read project info
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# ==========================================
# Allow GitHub Actions to impersonate the service account
# ==========================================

resource "google_service_account_iam_member" "github_actions_workload_identity" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

# ==========================================
# Outputs
# ==========================================

output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github.name
  description = "Workload Identity Provider name for GitHub Actions"
}

output "service_account_email" {
  value       = google_service_account.github_actions.email
  description = "Service Account email for GitHub Actions"
}
