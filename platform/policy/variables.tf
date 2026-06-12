variable "subscription_id" {
  description = "Azure subscription ID where policies are assigned"
  type        = string
}

variable "location" {
  description = "Azure region for policy resources"
  type        = string
}

variable "tags" {
  description = "Tags applied to policy resources"
  type        = map(string)
  default     = {}
}

variable "required_tag_keys" {
  description = "List of tag keys that must be present on all resources"
  type        = list(string)
  default     = ["Environment", "CostCenter", "TechOwner"]
}

variable "policy_effect_public_access" {
  description = "Policy effect for denying public network access (Deny or Audit)"
  type        = string
  default     = "Deny"
}

variable "policy_effect_diagnostics" {
  description = "Policy effect for diagnostic settings (DeployIfNotExists or AuditIfNotExists)"
  type        = string
  default     = "DeployIfNotExists"
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID to use in DiagnosticSettings policies"
  type        = string
}
