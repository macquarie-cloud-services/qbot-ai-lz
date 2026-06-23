#--------------------------------------------------------------
# AI Landing Zone — Outputs
#--------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the AI landing zone resource group"
  value       = module.resource_group.name
}

# Networking
output "spoke_vnet_id" {
  description = "Resource ID of the AI spoke VNet"
  value       = module.ai_networking.spoke_vnet_id
}

output "subnet_pe_id" {
  description = "Resource ID of the private endpoint subnet"
  value       = module.ai_networking.subnet_pe_id
}

# Data Services
output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = module.data_services.key_vault_id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.data_services.key_vault_uri
}

output "storage_account_name" {
  description = "Name of the main Storage Account"
  value       = module.data_services.storage_account_name
}

output "cosmosdb_endpoint" {
  description = "Cosmos DB account endpoint"
  value       = module.data_services.cosmosdb_endpoint
}

# AI Services
output "ai_foundry_hub_id" {
  description = "Resource ID of the AI Foundry Hub"
  value       = module.ai_services.ai_foundry_hub_id
}

output "ai_foundry_project_id" {
  description = "Resource ID of the AI Foundry Project"
  value       = module.ai_services.ai_foundry_project_id
}

output "ai_search_name" {
  description = "Name of the AI Search service"
  value       = module.ai_services.ai_search_name
}

output "speech_service_endpoint" {
  description = "Speech Service endpoint"
  value       = module.ai_services.speech_service_endpoint
}

output "document_intelligence_endpoint" {
  description = "Document Intelligence endpoint"
  value       = module.ai_services.document_intelligence_endpoint
}

output "computer_vision_endpoint" {
  description = "Computer Vision endpoint"
  value       = module.ai_services.computer_vision_endpoint
}

# App Services
output "webapp_nodejs_hostname" {
  description = "Default hostname of the Node.js WebApp"
  value       = module.app_services.webapp_nodejs_default_hostname
}

output "webapi_dotnet_hostname" {
  description = "Default hostname of the .NET WebAPI"
  value       = module.app_services.webapi_dotnet_default_hostname
}

output "function_app_hostname" {
  description = "Default hostname of the Function App"
  value       = module.app_services.function_app_default_hostname
}

# Managed Identity Principal IDs (needed for RBAC assignments in second apply)
output "webapp_nodejs_principal_id" {
  description = "Managed identity principal ID of the Node.js WebApp — use as app_service_principal_id in second apply"
  value       = module.app_services.webapp_nodejs_principal_id
}

output "webapi_dotnet_principal_id" {
  description = "Managed identity principal ID of the .NET WebAPI"
  value       = module.app_services.webapi_dotnet_principal_id
}

output "function_app_principal_id" {
  description = "Managed identity principal ID of the Function App"
  value       = module.app_services.function_app_principal_id
}

output "signalr_hostname" {
  description = "Hostname of the Azure SignalR Service"
  value       = module.realtime_services.signalr_hostname
}

output "app_gateway_public_ip" {
  description = "Public IP address of the Application Gateway. Null when enable_app_gateway = false."
  value       = var.feature_flags.enable_app_gateway ? module.app_gateway[0].public_ip_address : null
}

output "app_gateway_fqdn" {
  description = "Azure-assigned FQDN of the Application Gateway public IP. Null when enable_app_gateway = false."
  value       = var.feature_flags.enable_app_gateway ? module.app_gateway[0].public_fqdn : null
}

output "app_gateway_id" {
  description = "Resource ID of the Application Gateway. Null when enable_app_gateway = false."
  value       = var.feature_flags.enable_app_gateway ? module.app_gateway[0].app_gateway_id : null
}
