# terraform/ci-setup/azure/github-workload-identity.tf

# One-time setup for GitHub OIDC and CI/CD permissions
# Run once, then delete this file

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  default     = "lisekarimi/salutron"
}

variable "resource_group_name" {
  description = "Azure Resource Group name"
  type        = string
  default     = "salutron-rg"
}

variable "location" {
  description = "Azure location"
  type        = string
  default     = "francecentral"
}

# ==========================================
# Azure AD Application (Service Principal)
# ==========================================
resource "azuread_application" "github_actions" {
  display_name = "github-actions-salutron"
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

# ==========================================
# Federated Identity Credential (OIDC)
# ==========================================
resource "azuread_application_federated_identity_credential" "github_actions" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-federation"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository}:ref:refs/heads/main"
}

# ==========================================
# Role Assignments
# ==========================================
data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# ==========================================
# Outputs
# ==========================================
output "client_id" {
  value       = azuread_application.github_actions.client_id
  description = "Azure Client ID for GitHub Actions"
}

output "tenant_id" {
  value       = data.azurerm_subscription.current.tenant_id
  description = "Azure Tenant ID"
}

output "subscription_id" {
  value       = data.azurerm_subscription.current.subscription_id
  description = "Azure Subscription ID"
}
