# terraform/outputs.tf - this file contains the outputs for the project
output "ecr_repository_url" {
  value       = aws_ecr_repository.app_repo.repository_url
  description = "ECR repository URL"
}

output "app_runner_url" {
  value       = "https://${aws_apprunner_service.app.service_url}"
  description = "App Runner service URL"
}

output "app_runner_status" {
  value       = aws_apprunner_service.app.status
  description = "App Runner service status"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.app_bucket.id
  description = "S3 bucket name"
}
