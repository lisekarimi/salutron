# terraform/gcp/variables.tf - this file contains the variables for the project

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
  # No default - we FORCE user to specify it
}

variable "gcp_region" {
  description = "GCP region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
}

variable "custom_domain" {
  description = "Custom domain for the application (prod only)"
  type        = string
  default     = ""
}

variable "min_instances" {
  description = "Minimum number of instances for auto-scaling"
  type        = number
  default     = 0  # GCP Cloud Run can scale to 0!
}

variable "max_instances" {
  description = "Maximum number of instances for auto-scaling"
  type        = number
  default     = 1
}
