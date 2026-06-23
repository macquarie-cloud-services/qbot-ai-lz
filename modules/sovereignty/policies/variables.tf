#--------------------------------------------------------------
# Sovereignty Policies — Variables
#--------------------------------------------------------------

variable "management_group_id" {
  description = "Management Group ID where policies are assigned"
  type        = string
}

variable "enforce_private_only" {
  description = "Deny public network access on all Azure services"
  type        = bool
  default     = true
}

variable "enforce_cmk" {
  description = "Require customer-managed keys for encryption"
  type        = bool
  default     = true
}

variable "enforce_region_lock" {
  description = "Restrict deployments to allowed regions only"
  type        = bool
  default     = true
}

variable "enforce_identity" {
  description = "Require managed identity-only authentication"
  type        = bool
  default     = true
}

variable "allowed_regions" {
  description = "List of allowed Azure regions for enforcement"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags applied to policy assignments"
  type        = map(string)
  default     = {}
}
