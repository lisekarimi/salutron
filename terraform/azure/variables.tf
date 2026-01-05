# terraform/azure/variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Azure Resource Group name"
  type        = string
  default     = "salutron-rg"
}

variable "azure_region" {
  description = "Azure region"
  type        = string
  default     = "francecentral"
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
}

variable "min_instances" {
  description = "Minimum instances"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum instances"
  type        = number
  default     = 2
}
