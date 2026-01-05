# terraform/ci-setup/gcp-backend-setup.tf

# One-time setup for remote state
# Run once, then delete this file

# ==========================================
# Provider Configuration
# ==========================================
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "salutron"
  region  = "us-central1"
}

resource "google_storage_bucket" "terraform_state" {
  name          = "salutron-terraform-state-gcp"
  location      = "US"
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = {
    purpose     = "terraform-state"
    environment = "global"
    managed_by  = "terraform"
  }
}

output "state_bucket_name" {
  value       = google_storage_bucket.terraform_state.name
  description = "GCP Storage bucket for Terraform state"
}
