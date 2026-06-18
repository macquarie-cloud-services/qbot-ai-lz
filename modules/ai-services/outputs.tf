output "ai_foundry_hub_id" {
  description = "Resource ID of the Azure AI Foundry Hub. Null when enable_ai_foundry = false."
  value       = var.enable_ai_foundry ? azurerm_ai_foundry.hub[0].id : null
}

output "ai_foundry_hub_principal_id" {
  description = "System-assigned managed identity principal ID of the AI Foundry Hub. Null when enable_ai_foundry = false."
  value       = var.enable_ai_foundry ? azurerm_ai_foundry.hub[0].identity[0].principal_id : null
}

output "ai_foundry_project_id" {
  description = "Resource ID of the Azure AI Foundry Project. Null when enable_ai_foundry = false."
  value       = var.enable_ai_foundry ? azurerm_ai_foundry_project.project[0].id : null
}

output "ai_foundry_project_principal_id" {
  description = "System-assigned managed identity principal ID of the AI Foundry Project. Null when enable_ai_foundry = false."
  value       = var.enable_ai_foundry ? azurerm_ai_foundry_project.project[0].identity[0].principal_id : null
}

output "ai_search_id" {
  description = "Resource ID of the Azure AI Search service. Null when enable_ai_search = false."
  value       = var.enable_ai_search ? module.ai_search[0].resource_id : null
}

output "ai_search_name" {
  description = "Name of the Azure AI Search service. Null when enable_ai_search = false."
  value       = var.enable_ai_search ? module.ai_search[0].resource.name : null
}

output "speech_service_id" {
  description = "Resource ID of the Speech Service. Null when enable_speech = false."
  value       = var.enable_speech ? module.speech_service[0].resource_id : null
}

output "speech_service_endpoint" {
  description = "Endpoint URL of the Speech Service. Null when enable_speech = false."
  value       = var.enable_speech ? module.speech_service[0].endpoint : null
}

output "document_intelligence_id" {
  description = "Resource ID of the Document Intelligence service. Null when enable_document_intelligence = false."
  value       = var.enable_document_intelligence ? module.document_intelligence[0].resource_id : null
}

output "document_intelligence_endpoint" {
  description = "Endpoint URL of the Document Intelligence service. Null when enable_document_intelligence = false."
  value       = var.enable_document_intelligence ? module.document_intelligence[0].endpoint : null
}

output "computer_vision_id" {
  description = "Resource ID of the Computer Vision service. Null when enable_computer_vision = false."
  value       = var.enable_computer_vision ? module.computer_vision[0].resource_id : null
}

output "computer_vision_endpoint" {
  description = "Endpoint URL of the Computer Vision service. Null when enable_computer_vision = false."
  value       = var.enable_computer_vision ? module.computer_vision[0].endpoint : null
}

output "bing_search_id" {
  description = "Resource ID of the Bing Search (Grounding) resource. Null when enable_bing_search = false."
  value       = var.enable_bing_search ? azapi_resource.bing_search[0].id : null
}

output "bing_custom_search_id" {
  description = "Resource ID of the Bing Custom Search resource. Null when enable_bing_custom_search = false."
  value       = var.enable_bing_custom_search ? azapi_resource.bing_custom_search[0].id : null
}
