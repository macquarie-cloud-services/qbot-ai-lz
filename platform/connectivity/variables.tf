#--------------------------------------------------------------
# Platform Connectivity — Variables
#--------------------------------------------------------------

variable "subscription_id" {
  description = "Azure subscription ID where connectivity resources are deployed"
  type        = string
}

variable "location" {
  description = "Primary Azure region for this connectivity deployment"
  type        = string
}

variable "location_code" {
  description = "Short location code used in resource naming (e.g. 'aue' for australiaeast, 'ause' for australiasoutheast)"
  type        = string
}

variable "tags" {
  description = "Tags applied to all connectivity resources"
  type        = map(string)
  default     = {}
}

#--------------------------------------------------------------
# Hub Virtual Network
#--------------------------------------------------------------
variable "hub_vnet_address_space" {
  description = "Address space for the hub virtual network"
  type        = list(string)
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create inside the hub VNet.
    The map key is used to reference the subnet in downstream resources
    (e.g. Bastion, Firewall, VPN Gateway modules look up keys by name).

    Azure requires specific names for platform subnets:
      AzureFirewallSubnet  — minimum /26
      GatewaySubnet        — minimum /27
      AzureBastionSubnet   — minimum /26

    nsg_key optionally attaches an NSG to the subnet.
    The value must match a key in var.network_security_groups.
    Set to null (or omit) for no NSG on the subnet.

    Add any number of additional workload subnets as extra map entries.
  EOT
  type = map(object({
    name             = string
    address_prefixes = list(string)
    nsg_key          = optional(string)
  }))
}

variable "network_security_groups" {
  description = <<-EOT
    Map of custom NSGs to create and associate with hub subnets via the nsg_key
    field in var.subnets. The map key must match the nsg_key used in a subnet entry.

    Each NSG accepts an optional map of security rules. Omit security_rules (or set
    to {}) to create an NSG with no rules (Azure implicit deny-all applies).

    Example:
      network_security_groups = {
        mgmt = {
          name = "nsg-aue-hub-mgmt"
          security_rules = {
            allow_rdp = {
              name                       = "AllowRdpFromBastion"
              priority                   = 100
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              source_port_range          = "*"
              destination_port_range     = "3389"
              source_address_prefix      = "10.100.2.0/26"  # AzureBastionSubnet
              destination_address_prefix = "*"
            }
          }
        }
      }
  EOT
  type = map(object({
    name = string
    security_rules = optional(map(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), {})
  }))
  default = {}
}

#--------------------------------------------------------------
# Optional Features
#--------------------------------------------------------------
variable "enable_bastion" {
  description = "Deploy Azure Bastion in the hub VNet"
  type        = bool
  default     = true
}

variable "enable_firewall" {
  description = "Deploy Azure Firewall (significant cost — disable in dev/test)"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Deploy a VPN Gateway for on-premises connectivity (significant cost — disable in dev/test)"
  type        = bool
  default     = false
}

variable "bastion_sku" {
  description = "SKU for Azure Bastion (Basic or Standard)"
  type        = string
  default     = "Basic"
}

variable "firewall_sku_tier" {
  description = "SKU tier for Azure Firewall (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "vpn_gateway_sku" {
  description = "SKU for the VPN Gateway"
  type        = string
  default     = "VpnGw1"
}
