#--------------------------------------------------------------
# Platform Connectivity — Main
#
# Deploys the hub networking layer for one Azure region.
# Run once per region with the corresponding .tfvars file.
#
# Resources:
#   - Hub Resource Group
#   - Hub Virtual Network (fixed-name Azure subnets + mgmt subnet)
#   - Azure Bastion (optional, default: enabled)
#   - Azure Firewall (optional, default: disabled — cost)
#   - VPN Gateway  (optional, default: disabled — cost)
#   - Centralised Private DNS Zones linked to hub VNet (15 zones):
#       Key Vault, Storage Blob, Storage File,
#       App Services / Functions, Cosmos DB (NoSQL),
#       AI Search, Cognitive Services, Azure OpenAI,
#       AI Foundry API, AI Foundry Notebooks,
#       SignalR, Azure Monitor, OMS, ODS, Automation
#--------------------------------------------------------------

data "azurerm_client_config" "current" {}

locals {
  hub_name_prefix = "hub-${var.location_code}"
  common_tags = merge(var.tags, {
    Layer     = "platform-connectivity"
    ManagedBy = "Terraform-AVM"
  })

  # All private DNS zones required for QBot AI services
  private_dns_zones = {
    keyvault           = "privatelink.vaultcore.azure.net"
    blob               = "privatelink.blob.core.windows.net"
    file               = "privatelink.file.core.windows.net"
    web                = "privatelink.azurewebsites.net"
    cosmosdb           = "privatelink.documents.azure.com"
    search             = "privatelink.search.windows.net"
    cognitive_services = "privatelink.cognitiveservices.azure.com"
    openai             = "privatelink.openai.azure.com"
    aml_api            = "privatelink.api.azureml.ms"
    aml_notebooks      = "privatelink.notebooks.azure.net"
    signalr            = "privatelink.service.signalr.net"
    monitor            = "privatelink.monitor.azure.com"
    oms                = "privatelink.oms.opinsights.azure.com"
    ods                = "privatelink.ods.opinsights.azure.com"
    automation         = "privatelink.agentsvc.azure-automation.net"
  }

  # Map of nsg_key → resource ID from the custom NSG module instances.
  # Used to attach NSGs to hub subnets via the nsg_key field in var.subnets.
  hub_nsg_ids = {
    for k, _ in var.network_security_groups : k => module.hub_nsgs[k].resource_id
  }

  # Resolved subnet map: attach NSG resource IDs where nsg_key is set.
  hub_subnets = {
    for k, s in var.subnets : k => {
      name                      = s.name
      address_prefixes          = s.address_prefixes
      network_security_group_id = s.nsg_key != null ? local.hub_nsg_ids[s.nsg_key] : null
    }
  }
 }

#--------------------------------------------------------------
# Hub Resource Group
#--------------------------------------------------------------
module "resource_group_hub" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.2"

  # enable_telemetry = false   # disables modtm_telemetry

  name     = "rg-${var.location_code}-qbot-hub"
  location = var.location
  tags     = local.common_tags
}

#--------------------------------------------------------------
# Custom Hub NSGs
# Created for every entry in var.network_security_groups.
# Reference a key from this map in a subnet's nsg_key field to
# attach the NSG to that hub subnet.
#--------------------------------------------------------------
module "hub_nsgs" {
  for_each = var.network_security_groups
  source   = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version  = "~> 0.2"

  # enable_telemetry = false   # disables modtm_telemetry

  name                = each.value.name
  resource_group_name = module.resource_group_hub.name
  location            = var.location
  tags                = local.common_tags

  security_rules = each.value.security_rules
}

#--------------------------------------------------------------
# Hub Virtual Network
# https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm
#--------------------------------------------------------------
module "hub_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.7"

  # enable_telemetry = false   # disables modtm_telemetry

  name          = "vnet-${var.location_code}-qbot-hub"
  parent_id     = module.resource_group_hub.resource_id
  location      = var.location
  address_space = var.hub_vnet_address_space
  tags          = local.common_tags

  subnets = local.hub_subnets
}

#--------------------------------------------------------------
# Azure Bastion (optional)
# https://registry.terraform.io/modules/Azure/avm-res-network-bastionhost/azurerm
# The Bastion module creates and manages its own public IP internally.
#--------------------------------------------------------------
module "bastion" {
  count   = var.enable_bastion ? 1 : 0
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "~> 0.3"

  # enable_telemetry = false   # disables modtm_telemetry

  name      = "bas-${var.location_code}-hub"
  parent_id = module.resource_group_hub.resource_id
  location  = var.location
  tags      = local.common_tags

  sku = var.bastion_sku

  ip_configuration = {
    subnet_id              = module.hub_vnet.subnets["AzureBastionSubnet"].resource_id
    public_ip_address_name = "pip-bas-${var.location_code}-hub"
  }
}

#--------------------------------------------------------------
# Azure Firewall Policy (optional — required by Azure Firewall module)
#--------------------------------------------------------------
module "firewall_policy" {
  count   = var.enable_firewall ? 1 : 0
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "~> 0.3"

  # enable_telemetry = false   # disables modtm_telemetry

  name                = "afwp-${var.location_code}-hub"
  resource_group_name = module.resource_group_hub.name
  location            = var.location
  tags                = local.common_tags

  firewall_policy_sku = var.firewall_sku_tier
}

#--------------------------------------------------------------
# Azure Firewall Public IP (optional)
#--------------------------------------------------------------
module "firewall_pip" {
  count   = var.enable_firewall ? 1 : 0
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "~> 0.1"

  # enable_telemetry = false   # disables modtm_telemetry
  
  name                = "pip-${var.location_code}-afw-hub"
  resource_group_name = module.resource_group_hub.name
  location            = var.location
  tags                = local.common_tags

  allocation_method = "Static"
  sku               = "Standard"
  zones             = ["1", "2", "3"]
}

#--------------------------------------------------------------
# Azure Firewall (optional)
# https://registry.terraform.io/modules/Azure/avm-res-network-azurefirewall/azurerm
#--------------------------------------------------------------
module "firewall" {
  count   = var.enable_firewall ? 1 : 0
  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "~> 0.3"

  # enable_telemetry = false   # disables modtm_telemetry

  name                = "afw-${var.location_code}-hub"
  resource_group_name = module.resource_group_hub.name
  location            = var.location
  tags                = local.common_tags

  firewall_sku_tier  = var.firewall_sku_tier
  firewall_sku_name  = "AZFW_VNet"
  firewall_policy_id = module.firewall_policy[0].resource_id

  ip_configurations = {
    ipconfig = {
      name                 = "ipconfig-afw-${var.location_code}-hub"
      subnet_id            = module.hub_vnet.subnets["AzureFirewallSubnet"].resource_id
      public_ip_address_id = module.firewall_pip[0].resource_id
    }
  }
}

#--------------------------------------------------------------
# VPN Gateway (optional)
# https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetworkgateway/azurerm
#--------------------------------------------------------------
module "vpn_gateway" {
  count   = var.enable_vpn_gateway ? 1 : 0
  source  = "Azure/avm-ptn-vnetgateway/azurerm"
  version = "~> 0.10"
  
  # enable_telemetry = false   # disables modtm_telemetry

  name      = "vgw-${var.location_code}-hub"
  parent_id = module.resource_group_hub.resource_id
  location  = var.location
  tags      = local.common_tags

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = var.vpn_gateway_sku

  # Use the GatewaySubnet already created in the hub VNet
  subnet_creation_enabled           = false
  virtual_network_gateway_subnet_id = module.hub_vnet.subnets["GatewaySubnet"].resource_id
}

#--------------------------------------------------------------
# Centralised Private DNS Zones
# https://registry.terraform.io/modules/Azure/avm-res-network-privatednszone/azurerm
#
# One zone module per service — each linked to the hub VNet.
# Landing zones pass these zone IDs into their private endpoint config
# so DNS resolves correctly from all peered spokes.
#--------------------------------------------------------------
module "private_dns_zones" {
  for_each = local.private_dns_zones
  source   = "Azure/avm-res-network-privatednszone/azurerm"
  version  = "~> 0.3"

  enable_telemetry = false   # disables modtm_telemetry

  domain_name = each.value
  parent_id   = module.resource_group_hub.resource_id
  tags        = local.common_tags

  virtual_network_links = {
    hub = {
      vnetlinkname     = "vnetlink-hub-${each.key}"
      vnetid           = module.hub_vnet.resource_id
      autoregistration = false
    } 
  }
}
