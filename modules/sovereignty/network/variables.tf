#--------------------------------------------------------------
# Sovereignty Network — Variables
#
# Enforces private-only network topology and isolation controls.
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
  description = "Tags for network resources"
  type        = map(string)
  default     = {}
}
