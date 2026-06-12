variable "resource_group_name" {
  description = "Resource group name for all app service resources"
  type        = string
}

variable "resource_group_id" {
  description = "Resource group resource ID"
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

variable "subnet_app_id" {
  description = "Resource ID of the App Services VNet integration subnet (delegated)"
  type        = string
}

variable "subnet_func_id" {
  description = "Resource ID of the Function App VNet integration subnet (delegated)"
  type        = string
}

variable "subnet_pe_id" {
  description = "Resource ID of the private endpoint subnet"
  type        = string
}

variable "private_dns_zone_web_id" {
  description = "Resource ID of the App Services private DNS zone"
  type        = string
}

variable "private_dns_zone_blob_id" {
  description = "Resource ID of the Blob Storage private DNS zone (for function storage)"
  type        = string
}

#--------------------------------------------------------------
# App Service Plan
#--------------------------------------------------------------
variable "app_service_plan_name" {
  description = "Name for the App Service Plan"
  type        = string
}

variable "app_service_plan_sku" {
  description = "SKU for the App Service Plan (P1v3, P2v3, P3v3)"
  type        = string
  default     = "P1v3"
}

variable "enable_zone_redundancy" {
  description = "Enable zone redundancy for the App Service Plan (requires Premium v3)"
  type        = bool
  default     = false
}

#--------------------------------------------------------------
# Runtime versions
#--------------------------------------------------------------
variable "webapp_node_version" {
  description = "Node.js version for the WebApp (e.g. '20-lts')"
  type        = string
  default     = "20-lts"
}

variable "dotnet_version" {
  description = ".NET version for WebAPI, Memory Pipeline, and Function App (e.g. '8.0')"
  type        = string
  default     = "8.0"
}

#--------------------------------------------------------------
# App names
#--------------------------------------------------------------
variable "webapp_nodejs_name" {
  description = "Name for the Node.js WebApp"
  type        = string
}

variable "webapi_dotnet_name" {
  description = "Name for the .NET WebAPI App Service"
  type        = string
}

variable "memory_pipeline_name" {
  description = "Name for the .NET Memory Pipeline App Service"
  type        = string
}

variable "function_app_name" {
  description = "Name for the .NET Function App"
  type        = string
}

variable "func_storage_name" {
  description = "Name for the Function App storage account (3–24 chars, lowercase alphanumeric)"
  type        = string
}

#--------------------------------------------------------------
# App configuration (from upstream module outputs)
#--------------------------------------------------------------
variable "app_insights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  sensitive   = true
}

variable "key_vault_uri" {
  description = "URI of the Key Vault"
  type        = string
}

variable "cosmosdb_endpoint" {
  description = "Cosmos DB account endpoint URL"
  type        = string
}

variable "cosmosdb_database_name" {
  description = "Name of the Cosmos DB SQL database"
  type        = string
}

variable "ai_search_endpoint" {
  description = "Azure AI Search service endpoint URL"
  type        = string
  default     = ""
}

variable "ai_foundry_endpoint" {
  description = "Azure AI Foundry Hub endpoint URL"
  type        = string
  default     = ""
}

variable "speech_endpoint" {
  description = "Speech Service endpoint URL"
  type        = string
  default     = ""
}

variable "doc_intelligence_endpoint" {
  description = "Document Intelligence endpoint URL"
  type        = string
  default     = ""
}

variable "computer_vision_endpoint" {
  description = "Computer Vision endpoint URL"
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Name of the main storage account (for app config reference)"
  type        = string
  default     = ""
}

variable "webapi_cors_origins" {
  description = "CORS allowed origins for the WebAPI (typically the WebApp URL)"
  type        = list(string)
  default     = []
}

#--------------------------------------------------------------
# Feature Flags
#--------------------------------------------------------------
variable "enable_webapp_nodejs" {
  description = "Deploy the Node.js WebApp (chat frontend / orchestration layer). Disable in environments where only backend processing is needed."
  type        = bool
  default     = true
}

variable "enable_webapi_dotnet" {
  description = "Deploy the .NET WebAPI (REST backend). Disable in environments that expose the API through a different mechanism."
  type        = bool
  default     = true
}

variable "enable_memory_pipeline" {
  description = "Deploy the .NET Memory Pipeline background service. Disable in environments where memory ingestion is handled externally."
  type        = bool
  default     = true
}

variable "enable_function_app" {
  description = "Deploy the .NET Function App (serverless workers for indexing and document processing). Disable in environments that do not require serverless background processing."
  type        = bool
  default     = true
}
