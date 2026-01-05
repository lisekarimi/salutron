# terraform/azure/main.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # comment out the backend if you want to use local state
  backend "azurerm" {
    # Configuration provided via -backend-config flags in deploy.sh
  }
}

provider "azurerm" {
  features {}
}

# ==========================================
# Local Variables
# ==========================================
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ==========================================
# Container Registry
# ==========================================
resource "azurerm_container_registry" "acr" {
  name                = "${var.project_name}${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.azure_region
  sku                 = "Basic"
  admin_enabled       = true

  tags = local.common_tags
}

# ==========================================
# Log Analytics Workspace (required for Container Apps)
# ==========================================
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${local.name_prefix}-logs"
  resource_group_name = var.resource_group_name
  location            = var.azure_region
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# ==========================================
# Container Apps Environment
# ==========================================
resource "azurerm_container_app_environment" "env" {
  name                       = "${local.name_prefix}-env"
  resource_group_name        = var.resource_group_name
  location                   = var.azure_region
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  tags = local.common_tags
}

# ==========================================
# Container App
# ==========================================
resource "azurerm_container_app" "app" {
  name                         = "${local.name_prefix}-app"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  template {
    container {
      name   = var.project_name
      image  = "${azurerm_container_registry.acr.login_server}/${var.project_name}:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "OPENAI_API_KEY"
        value = var.openai_api_key
      }
    }

    min_replicas = var.min_instances
    max_replicas = var.max_instances
  }

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  ingress {
    external_enabled = true
    target_port      = 5000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = local.common_tags
}

# ==========================================
# Storage Account (for learning)
# ==========================================
resource "azurerm_storage_account" "storage" {
  name                     = "${var.project_name}${var.environment}storage"
  resource_group_name      = var.resource_group_name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.common_tags
}

# ==========================================
# Outputs
# ==========================================
output "container_registry_url" {
  value       = azurerm_container_registry.acr.login_server
  description = "Container Registry URL"
}

output "container_app_url" {
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
  description = "Container App URL"
}

output "resource_group" {
  value       = var.resource_group_name
  description = "Resource Group name"
}
