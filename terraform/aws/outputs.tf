# terraform/aws/outputs.tf - this file contains the outputs for the project
output "ecr_repository_url" {
  value       = aws_ecr_repository.app_repo.repository_url
  description = "ECR repository URL"
}

output "app_runner_url" {
  value       = "https://${aws_apprunner_service.app.service_url}"
  description = "App Runner default URL"
}

output "app_runner_status" {
  value       = aws_apprunner_service.app.status
  description = "App Runner service status"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.app_bucket.id
  description = "S3 bucket name"
}

# Custom domain outputs
output "custom_domain_status" {
  value       = var.custom_domain != "" ? aws_apprunner_custom_domain_association.custom_domain[0].status : "Not configured"
  description = "Custom domain association status"
}

output "custom_domain_dns_records" {
  value = var.custom_domain != "" ? [
    for record in aws_apprunner_custom_domain_association.custom_domain[0].certificate_validation_records : {
      name  = record.name
      type  = record.type
      value = record.value
    }
  ] : []
  description = "DNS records to add in Cloudflare for domain validation"
}

output "custom_domain_url" {
  value       = var.custom_domain != "" ? "https://${var.custom_domain}" : "No custom domain configured"
  description = "Custom domain URL (if configured)"
}
