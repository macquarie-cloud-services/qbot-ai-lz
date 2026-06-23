#--------------------------------------------------------------
# Sovereignty Encryption — Variables
#
# Enforces customer-managed keys (CMK) for all encryption.
#--------------------------------------------------------------

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_id" {
  description = "Landing zone resource group ID"
  type        = string
}

variable "cmk_key_vault_id" {
  description = "Key Vault resource ID for customer-managed encryption keys"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags for encryption resources"
  type        = map(string)
  default     = {}
}
