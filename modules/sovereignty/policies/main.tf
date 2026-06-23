#--------------------------------------------------------------
# Sovereignty Policies — Main
#
# Azure Policy assignments enforcing sovereign compliance:
#   1. Deny public network access on Key Vault, Storage, Cosmos DB, AI Services
#   2. Require CMK encryption on storage and databases
#   3. Restrict deployments to allowed regions
#   4. Require managed identity authentication
#
# NOTE: Policy definition IDs are examples and should be customized for your environment.
# Use `az policy definition list --query "[].{Name:displayName, ID:id}"` to find the correct IDs.
#--------------------------------------------------------------

#--------------------------------------------------------------
# Data source: Current client config (for subscription ID in policy paths)
#--------------------------------------------------------------
data "azurerm_client_config" "current" {}

#--------------------------------------------------------------
# Policy 1: Deny Public Network Access (Key Vault)
# Built-in: "Deny public network access for Key Vault"
#--------------------------------------------------------------
resource "azurerm_management_group_policy_assignment" "deny_public_keyvault" {
  count              = var.enforce_private_only ? 1 : 0
  name               = "Deny-Public-KeyVault-${var.environment}"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/405a5fef-3c21-4f28-9f66-3aaf46a16fb9"
  management_group_id  = var.management_group_id
  display_name         = "Deny public network access to Key Vault"
  description          = "This policy denies the creation of Key Vault namespaces with public network access"
}

#--------------------------------------------------------------
# Policy 2: Deny Public Network Access (Storage Account)
# Built-in: "Deny public network access to storage accounts"
#--------------------------------------------------------------
resource "azurerm_management_group_policy_assignment" "deny_public_storage" {
  count              = var.enforce_private_only ? 1 : 0
  name               = "Deny-Public-Storage-${var.environment}"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b2982f36-99f2-4c1d-a6c1-347cf76409f0"
  management_group_id  = var.management_group_id
  display_name         = "Deny public network access to storage accounts"
  description          = "This policy restricts creation of storage accounts with public network access"
}

#--------------------------------------------------------------
# Policy 3: Require Managed Identity (App Services)
# Built-in: "App Service apps should require managed identity"
#--------------------------------------------------------------
resource "azurerm_management_group_policy_assignment" "require_managed_identity" {
  count              = var.enforce_identity ? 1 : 0
  name               = "Require-ManagedIdentity-AppServices-${var.environment}"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2b9ad585-36a5-49df-a6c1-48b07918dd36"
  management_group_id  = var.management_group_id
  display_name         = "App Services should require managed identity"
  description          = "This policy audits App Service resources not using managed identity for authentication"
}

#--------------------------------------------------------------
# Policy 4: Allowed Locations (Region Lock)
# Built-in: "Allowed locations"
#--------------------------------------------------------------
resource "azurerm_management_group_policy_assignment" "allowed_regions" {
  count              = var.enforce_region_lock && length(var.allowed_regions) > 0 ? 1 : 0
  name               = "Allowed-Regions-${var.environment}"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-26f172e25ebf"
  management_group_id  = var.management_group_id
  display_name         = "Allowed locations - Data residency enforcement"
  description          = "Restricts resource deployment to approved regions for data residency compliance"

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_regions
    }
  })
}

