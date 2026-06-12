#--------------------------------------------------------------
# Platform Management — Outputs
# Consumed by landing-zones/ai via terraform_remote_state.
#--------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the management resource group"
  value       = module.resource_group_mgmt.name
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace (used for diagnostic settings)"
  value       = module.log_analytics.resource_id
}

output "log_analytics_workspace_customer_id" {
  description = "Customer ID (workspace ID) of the Log Analytics Workspace"
  value       = module.log_analytics.resource.workspace_id
  sensitive   = true
}

output "app_insights_id" {
  description = "Resource ID of the Application Insights instance"
  value       = module.app_insights.resource_id
}

output "app_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights (for legacy SDK support)"
  value       = module.app_insights.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Connection string for Application Insights (preferred over instrumentation key)"
  value       = module.app_insights.connection_string
  sensitive   = true
}
