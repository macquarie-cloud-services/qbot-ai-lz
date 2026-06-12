variable "resource_group_name" {
  description = "Resource group name for SignalR resources"
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

variable "subnet_pe_id" {
  description = "Resource ID of the private endpoint subnet"
  type        = string
}

variable "private_dns_zone_signalr_id" {
  description = "Resource ID of the SignalR private DNS zone"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace for diagnostic settings"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault to store the SignalR connection string. Leave empty to skip."
  type        = string
  default     = ""
}

#--------------------------------------------------------------
# SignalR Service
#--------------------------------------------------------------
variable "signalr_name" {
  description = "Name for the Azure SignalR Service"
  type        = string
}

variable "signalr_sku" {
  description = "SKU for SignalR Service (Free_F1, Standard_S1, Premium_P1)"
  type        = string
  default     = "Standard_S1"
}

variable "signalr_capacity" {
  description = "Number of units for the SignalR SKU"
  type        = number
  default     = 1
}

variable "signalr_cors_origins" {
  description = "List of allowed CORS origins for SignalR clients"
  type        = list(string)
  default     = []
}

#--------------------------------------------------------------
# Feature Flags
#--------------------------------------------------------------
variable "enable_signalr" {
  description = "Deploy the Azure SignalR Service. Set to false to skip this service in environments where real-time messaging is not required."
  type        = bool
  default     = true
}
