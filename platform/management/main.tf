#--------------------------------------------------------------
# Platform Management — Main
#
# Centralised observability for the QBot AI Landing Zone:
#   - Management Resource Group
#   - Log Analytics Workspace (platform-wide diagnostics sink)
#   - Application Insights (shared instance for all app tiers)
#
# All landing zone resources should send diagnostic logs to the
# Log Analytics workspace ID exported from this layer.
# App Services reference the App Insights connection string
# exported from this layer.
#--------------------------------------------------------------

locals {
  common_tags = merge(var.tags, {
    Layer     = "platform-management"
    ManagedBy = "Terraform-AVM"
  })
}

#--------------------------------------------------------------
# Management Resource Group
#--------------------------------------------------------------
module "resource_group_mgmt" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.2"

  name     = "rg-${var.location_code}-qbot-mgmt"
  location = var.location
  tags     = local.common_tags
}

#--------------------------------------------------------------
# Log Analytics Workspace
# https://registry.terraform.io/modules/Azure/avm-res-operationalinsights-workspace/azurerm
# Central diagnostics sink for all AI landing zone resources.
# Landing zones pass workspace_id into every module to wire up
# diagnostic settings automatically.
#--------------------------------------------------------------
module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "~> 0.4"

  name                = "law-${var.location_code}-qbot-mgmt"
  resource_group_name = module.resource_group_mgmt.name
  location            = var.location
  tags                = local.common_tags

  log_analytics_workspace_sku                        = var.log_analytics_sku
  log_analytics_workspace_retention_in_days          = var.log_analytics_retention_days
  log_analytics_workspace_internet_ingestion_enabled = true
  log_analytics_workspace_internet_query_enabled     = true
}

#--------------------------------------------------------------
# Application Insights
# https://registry.terraform.io/modules/Azure/avm-res-insights-component/azurerm
# Shared Application Insights instance — all App Services, Function Apps,
# and AI Foundry SDKs reference the connection string at runtime.
# Uses workspace-based mode (classic is deprecated).
#--------------------------------------------------------------
module "app_insights" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "~> 0.4"

  name                = "appi-${var.location_code}-qbot"
  resource_group_name = module.resource_group_mgmt.name
  location            = var.location
  tags                = local.common_tags

  application_type                    = var.app_insights_application_type
  workspace_id                        = module.log_analytics.resource_id
  internet_ingestion_enabled          = true
  internet_query_enabled              = true
  local_authentication_disabled       = false
  daily_data_cap_in_gb                = var.app_insights_daily_data_cap_gb > 0 ? var.app_insights_daily_data_cap_gb : null
  daily_data_cap_notifications_disabled = false
}
