# terraform/ci-setup/azure/azure-backend-setup.tf

# One-time setup for remote state
# Run once, then delete this file

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

# ==========================================
# Storage Account for Terraform State
# ==========================================
resource "azurerm_storage_account" "terraform_state" {
  name                     = "salutronterraformstate"  # Must be globally unique, lowercase, no hyphens
  resource_group_name      = "salutron-rg"
  location                 = "francecentral"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Purpose     = "terraform-state"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}

# ==========================================
# Blob Container for State Files
# ==========================================
resource "azurerm_storage_container" "terraform_state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}

# ==========================================
# Outputs
# ==========================================
output "storage_account_name" {
  value       = azurerm_storage_account.terraform_state.name
  description = "Storage account name for Terraform state"
}

output "container_name" {
  value       = azurerm_storage_container.terraform_state.name
  description = "Container name for Terraform state"
}

output "resource_group_name" {
  value       = "salutron-rg"
  description = "Resource group name"
}
