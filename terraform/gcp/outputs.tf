# terraform/gcp/outputs.tf - Output values

output "artifact_registry_url" {
  value       = "${var.gcp_region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app_repo.repository_id}"
  description = "Artifact Registry repository URL"
}

output "cloud_run_url" {
  value       = google_cloud_run_v2_service.app.uri
  description = "Cloud Run service URL"
}

output "cloud_run_status" {
  value       = google_cloud_run_v2_service.app.terminal_condition[0].state
  description = "Cloud Run service status"
}

output "storage_bucket_name" {
  value       = google_storage_bucket.app_bucket.name
  description = "Cloud Storage bucket name"
}

output "custom_domain_status" {
  value       = var.custom_domain != "" ? google_cloud_run_domain_mapping.custom_domain[0].status[0].conditions[0].type : "Not configured"
  description = "Custom domain mapping status"
}

output "custom_domain_records" {
  value = var.custom_domain != "" ? {
    type   = "CNAME"
    name   = var.custom_domain
    target = "ghs.googlehosted.com"
  } : null
  description = "DNS record to add for custom domain"
}

output "custom_domain_url" {
  value       = var.custom_domain != "" ? "https://${var.custom_domain}" : "No custom domain configured"
  description = "Custom domain URL (if configured)"
}
