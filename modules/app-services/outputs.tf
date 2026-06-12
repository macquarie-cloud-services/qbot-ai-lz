output "app_service_plan_id" {
  description = "Resource ID of the App Service Plan"
  value       = module.app_service_plan.resource_id
}

output "webapp_nodejs_id" {
  description = "Resource ID of the Node.js WebApp. Null when enable_webapp_nodejs = false."
  value       = var.enable_webapp_nodejs ? module.webapp_nodejs[0].resource_id : null
}

output "webapp_nodejs_principal_id" {
  description = "System-assigned managed identity principal ID of the Node.js WebApp. Null when enable_webapp_nodejs = false."
  value       = var.enable_webapp_nodejs ? module.webapp_nodejs[0].identity[0].principal_id : null
}

output "webapp_nodejs_default_hostname" {
  description = "Default hostname of the Node.js WebApp. Null when enable_webapp_nodejs = false."
  value       = var.enable_webapp_nodejs ? module.webapp_nodejs[0].default_hostname : null
}

output "webapi_dotnet_id" {
  description = "Resource ID of the .NET WebAPI. Null when enable_webapi_dotnet = false."
  value       = var.enable_webapi_dotnet ? module.webapi_dotnet[0].resource_id : null
}

output "webapi_dotnet_principal_id" {
  description = "System-assigned managed identity principal ID of the .NET WebAPI. Null when enable_webapi_dotnet = false."
  value       = var.enable_webapi_dotnet ? module.webapi_dotnet[0].identity[0].principal_id : null
}

output "webapi_dotnet_default_hostname" {
  description = "Default hostname of the .NET WebAPI. Null when enable_webapi_dotnet = false."
  value       = var.enable_webapi_dotnet ? module.webapi_dotnet[0].default_hostname : null
}

output "memory_pipeline_id" {
  description = "Resource ID of the .NET Memory Pipeline App Service. Null when enable_memory_pipeline = false."
  value       = var.enable_memory_pipeline ? module.memory_pipeline_dotnet[0].resource_id : null
}

output "memory_pipeline_principal_id" {
  description = "System-assigned managed identity principal ID of the Memory Pipeline. Null when enable_memory_pipeline = false."
  value       = var.enable_memory_pipeline ? module.memory_pipeline_dotnet[0].identity[0].principal_id : null
}

output "function_app_id" {
  description = "Resource ID of the .NET Function App. Null when enable_function_app = false."
  value       = var.enable_function_app ? module.function_app[0].resource_id : null
}

output "function_app_principal_id" {
  description = "System-assigned managed identity principal ID of the Function App. Null when enable_function_app = false."
  value       = var.enable_function_app ? module.function_app[0].identity[0].principal_id : null
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App. Null when enable_function_app = false."
  value       = var.enable_function_app ? module.function_app[0].default_hostname : null
}
