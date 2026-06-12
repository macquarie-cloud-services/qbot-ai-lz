variable "resource_group_name" {
  description = "Resource group name for all AI service resources"
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

variable "subnet_pe_id" {
  description = "Resource ID of the private endpoint subnet"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace for diagnostic settings"
  type        = string
}

variable "app_service_principal_id" {
  description = "Object ID of the App Services managed identity to grant RBAC roles on AI services. Leave empty to skip RBAC assignments."
  type        = string
  default     = ""
}

#--------------------------------------------------------------
# Private DNS Zone IDs
#--------------------------------------------------------------
variable "private_dns_zone_blob_id" {
  description = "Resource ID of the Blob Storage private DNS zone"
  type        = string
}

variable "private_dns_zone_file_id" {
  description = "Resource ID of the File Storage private DNS zone"
  type        = string
}

variable "private_dns_zone_keyvault_id" {
  description = "Resource ID of the Key Vault private DNS zone"
  type        = string
}

variable "private_dns_zone_cognitive_services_id" {
  description = "Resource ID of the Cognitive Services private DNS zone"
  type        = string
}

variable "private_dns_zone_search_id" {
  description = "Resource ID of the AI Search private DNS zone"
  type        = string
}

variable "private_dns_zone_aml_api_id" {
  description = "Resource ID of the AI Foundry (AML) API private DNS zone"
  type        = string
}

variable "private_dns_zone_aml_notebooks_id" {
  description = "Resource ID of the AI Foundry Notebooks private DNS zone"
  type        = string
}

#--------------------------------------------------------------
# AI Foundry
#--------------------------------------------------------------
variable "ai_foundry_hub_name" {
  description = "Name for the Azure AI Foundry Hub"
  type        = string
}

variable "ai_foundry_project_name" {
  description = "Name for the Azure AI Foundry Project"
  type        = string
}

variable "ai_foundry_storage_name" {
  description = "Storage account name for AI Foundry Hub (3–24 chars, lowercase alphanumeric)"
  type        = string
}

variable "ai_foundry_keyvault_name" {
  description = "Key Vault name for AI Foundry Hub"
  type        = string
}

#--------------------------------------------------------------
# AI Search
#--------------------------------------------------------------
variable "ai_search_name" {
  description = "Name for the Azure AI Search service"
  type        = string
}

variable "ai_search_sku" {
  description = "SKU for AI Search (free, basic, standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2)"
  type        = string
  default     = "basic"
}

variable "ai_search_replica_count" {
  description = "Number of replicas for AI Search (1–12)"
  type        = number
  default     = 1
}

variable "ai_search_partition_count" {
  description = "Number of partitions for AI Search (1, 2, 3, 4, 6, or 12)"
  type        = number
  default     = 1
}

#--------------------------------------------------------------
# Speech Service
#--------------------------------------------------------------
variable "speech_service_name" {
  description = "Name for the Speech Service Cognitive Services account"
  type        = string
}

variable "speech_sku" {
  description = "SKU for Speech Service (F0 = free, S0 = standard)"
  type        = string
  default     = "S0"
}

#--------------------------------------------------------------
# Document Intelligence
#--------------------------------------------------------------
variable "doc_intelligence_name" {
  description = "Name for the Document Intelligence Cognitive Services account"
  type        = string
}

variable "doc_intelligence_sku" {
  description = "SKU for Document Intelligence (F0 = free, S0 = standard)"
  type        = string
  default     = "S0"
}

#--------------------------------------------------------------
# Computer Vision
#--------------------------------------------------------------
variable "computer_vision_name" {
  description = "Name for the Computer Vision Cognitive Services account"
  type        = string
}

variable "computer_vision_sku" {
  description = "SKU for Computer Vision (F0 = free, S1 = standard)"
  type        = string
  default     = "S1"
}

#--------------------------------------------------------------
# Bing Search
#--------------------------------------------------------------
variable "bing_search_name" {
  description = "Name for the Bing Search (Grounding) resource"
  type        = string
}

variable "bing_search_sku" {
  description = "SKU for Bing Search (G1 = grounding standard)"
  type        = string
  default     = "G1"
}

variable "bing_custom_search_name" {
  description = "Name for the Bing Custom Search resource"
  type        = string
}

variable "bing_custom_search_sku" {
  description = "SKU for Bing Custom Search (F0 = free, S1 = standard)"
  type        = string
  default     = "S1"
}

#--------------------------------------------------------------
# Feature Flags
#--------------------------------------------------------------
variable "enable_ai_foundry" {
  description = "Deploy the Azure AI Foundry Hub and Project (including their dedicated Storage Account and Key Vault). Set to false in environments that use an externally managed Foundry workspace."
  type        = bool
  default     = true
}

variable "enable_ai_search" {
  description = "Deploy the Azure AI Search service. Set to false in environments where semantic / vector search is not required (e.g. prod environments relying on pre-built indexes)."
  type        = bool
  default     = true
}

variable "enable_speech" {
  description = "Deploy the Azure AI Speech Service (speech-to-text / text-to-speech). Set to false in environments where voice interaction is not needed."
  type        = bool
  default     = true
}

variable "enable_document_intelligence" {
  description = "Deploy the Azure AI Document Intelligence service (form/document parsing). Set to false in environments that do not process documents."
  type        = bool
  default     = true
}

variable "enable_computer_vision" {
  description = "Deploy the Azure AI Computer Vision service (image analysis). Set to false in environments that do not require image processing."
  type        = bool
  default     = true
}

variable "enable_bing_search" {
  description = "Deploy the Bing Search (Grounding) resource for web-grounded responses. Set to false in air-gapped or cost-sensitive environments."
  type        = bool
  default     = false
}

variable "enable_bing_custom_search" {
  description = "Deploy the Bing Custom Search resource. Set to false when custom web search grounding is not required."
  type        = bool
  default     = false
}
