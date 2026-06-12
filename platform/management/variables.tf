#--------------------------------------------------------------
# Platform Management — Variables
#--------------------------------------------------------------

variable "subscription_id" {
  description = "Azure subscription ID where management resources are deployed"
  type        = string
}

variable "location" {
  description = "Azure region for the management layer (typically primary region)"
  type        = string
}

variable "location_code" {
  description = "Short location code used in resource naming (e.g. 'aue' for australiaeast)"
  type        = string
}

variable "tags" {
  description = "Tags applied to all management resources"
  type        = map(string)
  default     = {}
}

#--------------------------------------------------------------
# Log Analytics Workspace
#--------------------------------------------------------------
variable "log_analytics_sku" {
  description = "SKU for the Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_days" {
  description = "Retention period in days for Log Analytics data (30–730)"
  type        = number
  default     = 90
}

#--------------------------------------------------------------
# Application Insights
#--------------------------------------------------------------
variable "app_insights_application_type" {
  description = "Application type for Application Insights (web, other)"
  type        = string
  default     = "web"
}

variable "app_insights_daily_data_cap_gb" {
  description = "Daily data cap in GB for Application Insights sampling. Set to 0 to disable cap."
  type        = number
  default     = 10
}
