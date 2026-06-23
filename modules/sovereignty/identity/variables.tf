#--------------------------------------------------------------
# Sovereignty Identity — Variables
#
# Enforces managed identity-only authentication.
#--------------------------------------------------------------

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_id" {
  description = "Landing zone resource group ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags for identity resources"
  type        = map(string)
  default     = {}
}
