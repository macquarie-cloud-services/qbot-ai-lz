#--------------------------------------------------------------
# App Gateway Module — Variables
#--------------------------------------------------------------

variable "resource_group_name" {
  description = "Resource group name for all App Gateway resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

#--------------------------------------------------------------
# Naming
#--------------------------------------------------------------
variable "app_gateway_name" {
  description = "Name for the Application Gateway resource"
  type        = string
}

variable "waf_policy_name" {
  description = "Name for the WAF policy resource"
  type        = string
}

variable "public_ip_name" {
  description = "Name for the Application Gateway public IP"
  type        = string
}

#--------------------------------------------------------------
# Networking
#--------------------------------------------------------------
variable "subnet_id" {
  description = "Resource ID of the dedicated ApplicationGateway subnet (minimum /24)"
  type        = string
}

variable "zones" {
  description = "Availability zones for the public IP and Application Gateway. Use [] for regions without zones (e.g. australiasoutheast)."
  type        = list(string)
  default     = ["1", "2", "3"]
}

#--------------------------------------------------------------
# Capacity / Autoscaling
#--------------------------------------------------------------
variable "capacity" {
  description = "Fixed instance count (1–125 for WAF_v2). Set to null when autoscale_min_capacity is configured."
  type        = number
  default     = 1
}

variable "autoscale_min_capacity" {
  description = "Minimum instance count for autoscaling. When set, var.capacity is ignored."
  type        = number
  default     = null
}

variable "autoscale_max_capacity" {
  description = "Maximum instance count when autoscaling is enabled."
  type        = number
  default     = 10
}

#--------------------------------------------------------------
# WAF
#--------------------------------------------------------------
variable "waf_mode" {
  description = "WAF mode. Use 'Detection' during initial rollout; 'Prevention' for production."
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "waf_mode must be 'Detection' or 'Prevention'."
  }
}

#--------------------------------------------------------------
# SSL Certificate
# Provide EITHER ssl_cert_pfx_b64 + ssl_cert_pfx_password
# OR ssl_cert_key_vault_secret_id (takes precedence).
#
# For Key Vault certificates the App Gateway requires a
# user-assigned managed identity — one is created automatically
# when ssl_cert_key_vault_secret_id is set. Grant that identity
# the 'Key Vault Secrets User' role on the vault; the resource ID
# is surfaced via the identity_principal_id output.
#--------------------------------------------------------------
variable "ssl_cert_pfx_b64" {
  description = "Base64-encoded PFX certificate for HTTPS listener. Used when ssl_cert_key_vault_secret_id is empty."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssl_cert_pfx_password" {
  description = "Password for the PFX certificate."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssl_cert_key_vault_secret_id" {
  description = "Unversioned Key Vault secret URI for the TLS certificate (e.g. https://<vault>.vault.azure.net/secrets/<cert-name>). When set, overrides ssl_cert_pfx_b64."
  type        = string
  default     = ""
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault. Required when ssl_cert_key_vault_secret_id is set (used for RBAC assignment)."
  type        = string
  default     = ""
}

#--------------------------------------------------------------
# Backend
#--------------------------------------------------------------
variable "webapp_fqdn" {
  description = "Fully-qualified hostname of the Node.js WebApp (e.g. myapp.azurewebsites.net). Used as the default backend."
  type        = string
}

variable "webapi_fqdn" {
  description = "Fully-qualified hostname of the .NET WebAPI (e.g. myapi.azurewebsites.net). Receives /api/* traffic."
  type        = string
}

variable "webapi_health_path" {
  description = "Health probe path for the WebAPI backend."
  type        = string
  default     = "/health"
}

#--------------------------------------------------------------
# Observability
#--------------------------------------------------------------
variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace for diagnostic settings."
  type        = string
}
