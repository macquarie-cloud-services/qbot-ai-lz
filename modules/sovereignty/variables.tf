#--------------------------------------------------------------
# Sovereignty Module — Variables
#
# Applies regulated/sovereign compliance controls to the landing zone.
# Enables granular enforcement of:
#   - Private-only network access (deny public endpoints)
#   - Customer-managed keys (CMK) for encryption
#   - Region-lock enforcement (data residency)
#   - Managed identity-only authentication
#
# Usage:
#   module "sovereignty" {
#     source = "../../modules/sovereignty"
#     count  = var.sovereignty_profile.enabled ? 1 : 0
#
#     location                = var.location
#     environment             = var.environment
#     resource_group_id       = azurerm_resource_group.this.id
#     sovereignty_profile     = var.sovereignty_profile
#     management_group_id     = var.management_group_id
#     tags                    = var.tags
#   }
#--------------------------------------------------------------

variable "location" {
  description = "Azure region where the landing zone is deployed"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "resource_group_id" {
  description = "Resource ID of the landing zone resource group"
  type        = string
}

variable "management_group_id" {
  description = "Azure Management Group ID where sovereignty policies will be assigned (policy scope)"
  type        = string
}

variable "sovereignty_profile" {
  description = <<-EOT
    Granular sovereignty control toggles.
    - enabled: master toggle; enables all sovereignty features
    - enforce_private_only: deny all public endpoints (Key Vault, Storage, Cosmos DB, AI services)
    - enforce_cmk: require customer-managed keys for all encryption
    - enforce_region_lock: restrict deployments to single region (data residency)
    - enforce_identity: require managed identity-only auth (no shared keys, connection strings)
  EOT
  type = object({
    enabled              = bool
    enforce_private_only = bool
    enforce_cmk          = bool
    enforce_region_lock  = bool
    enforce_identity     = bool
  })
  default = {
    enabled              = false
    enforce_private_only = false
    enforce_cmk          = false
    enforce_region_lock  = false
    enforce_identity     = false
  }
}

variable "allowed_regions" {
  description = "List of allowed Azure regions when enforce_region_lock is enabled"
  type        = list(string)
  default     = []
}

variable "cmk_key_vault_id" {
  description = "Key Vault ID for customer-managed encryption keys (required when enforce_cmk = true)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all sovereignty resources"
  type        = map(string)
  default     = {}
}
