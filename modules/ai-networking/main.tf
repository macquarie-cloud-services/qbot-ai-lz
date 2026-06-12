#--------------------------------------------------------------
# AI Networking Module — Main
#
# Creates:
#   - NSG for AI services subnet (restrict to private endpoints)
#   - NSG for app subnet (HTTPS inbound from load balancer + VNet)
#   - NSG for function subnet (HTTPS inbound, deny-all)
#   - NSG for data subnet (no inbound from internet)
#   - NSG for private endpoint subnet (deny all inbound from internet)
#   - Spoke VNet with 6 subnets
#   - VNet peering: spoke → hub
#   - VNet peering: hub  → spoke (created in hub RG)
#   - VNet link of spoke to all hub Private DNS Zones
#--------------------------------------------------------------

#--------------------------------------------------------------
# NSG — Private Endpoint Subnet
# No inbound from internet; all traffic via private IPs only.
#--------------------------------------------------------------
module "nsg_pe" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.2"

  name                = "nsg-${var.location_code}-pe-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rules = {
    deny_internet_inbound = {
      name                       = "DenyInternetInbound"
      access                     = "Deny"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    allow_vnet_inbound = {
      name                       = "AllowVnetInbound"
      access                     = "Allow"
      direction                  = "Inbound"
      priority                   = 200
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    deny_all_inbound = {
      name                       = "DenyAllInbound"
      access                     = "Deny"
      direction                  = "Inbound"
      priority                   = 4096
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

#--------------------------------------------------------------
# NSG — App Services Subnet
# Allows HTTPS inbound from VNet; blocks direct internet.
#--------------------------------------------------------------
module "nsg_app" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.2"

  name                = "nsg-${var.location_code}-app-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rules = {
    allow_https_inbound = {
      name                       = "AllowHttpsInbound"
      access                     = "Allow"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    allow_http_inbound = {
      name                       = "AllowHttpInbound"
      access                     = "Allow"
      direction                  = "Inbound"
      priority                   = 110
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    deny_all_inbound = {
      name                       = "DenyAllInbound"
      access                     = "Deny"
      direction                  = "Inbound"
      priority                   = 4096
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

#--------------------------------------------------------------
# NSG — Function App Subnet
#--------------------------------------------------------------
module "nsg_func" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.2"

  name                = "nsg-${var.location_code}-func-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rules = {
    allow_https_inbound = {
      name                       = "AllowHttpsInbound"
      access                     = "Allow"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    deny_all_inbound = {
      name                       = "DenyAllInbound"
      access                     = "Deny"
      direction                  = "Inbound"
      priority                   = 4096
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

#--------------------------------------------------------------
# NSG — Data Subnet (Cosmos DB service endpoint rules, etc.)
#--------------------------------------------------------------
module "nsg_data" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.2"

  name                = "nsg-${var.location_code}-data-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rules = {
    deny_internet_inbound = {
      name                       = "DenyInternetInbound"
      access                     = "Deny"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    allow_vnet_inbound = {
      name                       = "AllowVnetInbound"
      access                     = "Allow"
      direction                  = "Inbound"
      priority                   = 200
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    deny_all_inbound = {
      name                       = "DenyAllInbound"
      access                     = "Deny"
      direction                  = "Inbound"
      priority                   = 4096
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

#--------------------------------------------------------------
# NSG — Management Subnet (Bastion, jump servers)
#--------------------------------------------------------------
module "nsg_mgmt" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.2"

  name                = "nsg-${var.location_code}-mgmt-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rules = {
    allow_rdp_from_vnet = {
      name                       = "AllowRdpFromVnet"
      access                     = "Allow"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    allow_ssh_from_vnet = {
      name                       = "AllowSshFromVnet"
      access                     = "Allow"
      direction                  = "Inbound"
      priority                   = 110
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    deny_all_inbound = {
      name                       = "DenyAllInbound"
      access                     = "Deny"
      direction                  = "Inbound"
      priority                   = 4096
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

#--------------------------------------------------------------
# Custom Spoke NSGs
# Created for every entry in var.network_security_groups.
# Reference a key from this map in a subnet's nsg_key field to
# attach the NSG to that spoke subnet.
# Note: the reserved keys app, func, data, pe, mgmt always resolve
# to the hardcoded NSGs above and must not be used here.
#--------------------------------------------------------------
module "custom_nsgs" {
  for_each = var.network_security_groups
  source   = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version  = "~> 0.2"

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rules = each.value.security_rules
}

#--------------------------------------------------------------
# AI Spoke Virtual Network
# Subnets are driven by var.subnets — add entries in the calling
# tfvars to provision additional subnets without module changes.
#--------------------------------------------------------------

# Resolve nsg_key strings (from var.subnets) to actual NSG resource IDs.
# Keys match the module-managed NSGs created above, merged with any custom NSGs.
locals {
  _nsg_ids = merge(
    {
      app  = module.nsg_app.resource_id
      func = module.nsg_func.resource_id
      data = module.nsg_data.resource_id
      pe   = module.nsg_pe.resource_id
      mgmt = module.nsg_mgmt.resource_id
    },
    { for k, _ in var.network_security_groups : k => module.custom_nsgs[k].resource_id }
  )

  spoke_subnets = {
    for k, s in var.subnets : k => {
      name                              = s.name
      address_prefixes                  = s.address_prefixes
      network_security_group_id         = s.nsg_key != null ? local._nsg_ids[s.nsg_key] : null
      private_endpoint_network_policies = s.private_endpoint_network_policies
      delegation                        = s.delegation
    }
  }
}

module "spoke_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.7"

  name          = var.vnet_name
  parent_id     = var.resource_group_id
  location      = var.location
  address_space = var.vnet_address_space
  tags          = var.tags

  subnets = local.spoke_subnets

  # Spoke → Hub peering (conditional)
  peerings = var.enable_hub_peering ? {
    to_hub = {
      name                         = "peer-${var.location_code}-spoke-to-hub"
      remote_virtual_network_id    = var.hub_vnet_id
      allow_virtual_network_access = true
      allow_forwarded_traffic      = true
      allow_gateway_transit        = false
      use_remote_gateways          = var.use_remote_gateways
    }
  } : {}
}

#--------------------------------------------------------------
# Hub → Spoke Peering
# Created in the hub RG so spoke traffic can flow back.
# Requires Network Contributor on the hub RG.
#--------------------------------------------------------------
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count    = var.enable_hub_peering ? 1 : 0
  provider = azurerm.hub # hub-side resource — must land in the hub subscription

  name                         = "peer-${var.location_code}-hub-to-${var.environment}-ai"
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = module.spoke_vnet.resource_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.use_remote_gateways
  use_remote_gateways          = false
}

#--------------------------------------------------------------
# Spoke VNet Links to all hub Private DNS Zones
# Enables DNS resolution from the spoke for all private endpoints.
#--------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "spoke_links" {
  for_each = var.enable_hub_peering ? var.private_dns_zone_ids : {}
  provider = azurerm.hub # hub-side resource — must land in the hub subscription

  name                  = "vnetlink-${var.environment}-${var.location_code}-${each.key}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = module.spoke_vnet.resource_id
  registration_enabled  = false
  tags                  = var.tags
}
