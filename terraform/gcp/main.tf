# terraform/gcp/main.tf - Main infrastructure configuration for GCP

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
  # comment out the backend if you want to use local state
  backend "gcs" {
    bucket = "salutron-terraform-state-gcp"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.gcp_region
}

# ==========================================
# Local Variables
# ==========================================
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ==========================================
# Cloud Storage Bucket
# ==========================================
resource "google_storage_bucket" "app_bucket" {
  name          = "${local.name_prefix}-bucket-${var.project_id}"
  location      = var.gcp_region
  force_destroy = true

  uniform_bucket_level_access = true

  labels = local.common_labels
}

# ==========================================
# Artifact Registry Repository
# ==========================================
resource "google_artifact_registry_repository" "app_repo" {
  location      = var.gcp_region
  repository_id = "${local.name_prefix}-repo"
  description   = "Docker repository for ${var.project_name}"
  format        = "DOCKER"

  labels = local.common_labels
}

# ==========================================
# Service Account for Cloud Run
# ==========================================
resource "google_service_account" "cloudrun_sa" {
  account_id   = "${local.name_prefix}-sa"
  display_name = "Cloud Run Service Account for ${local.name_prefix}"
}

# Grant permissions to pull from Artifact Registry
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# ==========================================
# Cloud Run Service
# ==========================================
resource "google_cloud_run_v2_service" "app" {
  name     = "${local.name_prefix}-service"
  location = var.gcp_region

  template {
    service_account = google_service_account.cloudrun_sa.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = "${var.gcp_region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app_repo.repository_id}/${var.project_name}:latest"

      ports {
        container_port = 5000
      }

      env {
        name  = "OPENAI_API_KEY"
        value = var.openai_api_key
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  labels = local.common_labels
}

# ==========================================
# Allow unauthenticated access
# ==========================================
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  name     = google_cloud_run_v2_service.app.name
  location = google_cloud_run_v2_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ==========================================
# Custom Domain Mapping (Production Only)
# ==========================================
resource "google_cloud_run_domain_mapping" "custom_domain" {
  count    = var.custom_domain != "" ? 1 : 0
  name     = var.custom_domain
  location = var.gcp_region

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.app.name
  }
}

# ==========================================
# Monitoring - Notification Channel
# ==========================================
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Alerts - ${var.environment}"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

# ==========================================
# Alert Policy - 4xx Errors
# ==========================================
resource "google_monitoring_alert_policy" "cloudrun_4xx" {
  display_name = "${local.name_prefix} - 4xx Errors"
  combiner     = "OR"

  conditions {
    display_name = "4xx Error Rate"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.app.name}\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"4xx\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

# ==========================================
# Alert Policy - 5xx Errors
# ==========================================
resource "google_monitoring_alert_policy" "cloudrun_5xx" {
  display_name = "${local.name_prefix} - 5xx Errors"
  combiner     = "OR"

  conditions {
    display_name = "5xx Error Rate"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.app.name}\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"5xx\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}
