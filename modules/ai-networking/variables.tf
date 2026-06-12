variable "resource_group_name" {
  description = "Resource group name where networking resources are created"
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

variable "location_code" {
  description = "Short location code (e.g. 'aue', 'ause')"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "vnet_name" {
  description = "Name for the spoke Virtual Network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the spoke Virtual Network"
  type        = list(string)
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create in the AI spoke VNet. The map key is used to reference
    the subnet in outputs and by downstream modules.

    The following well-known keys are expected by the named module outputs and must
    be present unless those outputs are not consumed:
      app  — App Services VNet integration subnet (requires delegation)
      func — Function App VNet integration subnet (requires delegation)
      data — Data-tier subnet
      svc  — AI cognitive services subnet
      pe   — Private endpoints subnet
      mgmt — Management subnet

    nsg_key attaches one of the module-managed NSGs to the subnet:
      "app"  → AllowHTTPS + AllowHTTP inbound from VNet; deny-all default
      "func" → AllowHTTPS inbound from VNet; deny-all default
      "data" → DenyInternet inbound; AllowVNet inbound
      "pe"   → DenyInternet inbound; AllowVNet inbound
      "mgmt" → AllowRDP/SSH from VNet; deny-all default
      null   → No NSG attached to the subnet

    Add extra entries to this map to provision additional subnets without any
    module changes.
  EOT
  type = map(object({
    name                              = string
    address_prefixes                  = list(string)
    nsg_key                           = optional(string)
    private_endpoint_network_policies = optional(string)
    delegation = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })))
  }))
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub Virtual Network (for peering). Required when enable_hub_peering = true."
  type        = string
  default     = ""
}

variable "hub_vnet_name" {
  description = "Name of the hub Virtual Network (for hub-side peering resource). Required when enable_hub_peering = true."
  type        = string
  default     = ""
}

variable "hub_resource_group_name" {
  description = "Resource group name of the hub (for hub-side peering and DNS zone links). Required when enable_hub_peering = true."
  type        = string
  default     = ""
}

variable "use_remote_gateways" {
  description = "Use remote VPN/ExpressRoute gateways in the hub. Set to true only if enable_vpn_gateway = true in connectivity."
  type        = bool
  default     = false
}

variable "private_dns_zone_ids" {
  description = "Map of DNS zone key to an object containing name and resource_id. Used to create VNet links from the spoke to each hub-managed private DNS zone. Required when enable_hub_peering = true."
  type = map(object({
    name        = string
    resource_id = string
  }))
  default = {}
}

#--------------------------------------------------------------
# Feature Flags
#--------------------------------------------------------------
variable "enable_hub_peering" {
  description = "Establish hub-spoke VNet peering (both directions) and link the spoke to all hub private DNS zones. Set to false for standalone/isolated environments that do not require connectivity to the hub network."
  type        = bool
  default     = true
}

variable "network_security_groups" {
  description = <<-EOT
    Map of custom NSGs to create in addition to the five module-managed NSGs
    (app, func, data, pe, mgmt). Define extra NSGs here when the built-in rules
    do not cover a use case (e.g. a DMZ subnet with specific port rules).

    The map key must match the nsg_key used in the corresponding subnet entry
    inside var.subnets. Built-in keys (app, func, data, pe, mgmt) are reserved
    and must not be used here — they always resolve to the hardcoded NSGs.

    Example:
      network_security_groups = {
        dmz = {
          name = "nsg-aue-ai-dmz-dev"
          security_rules = {
            allow_https_inbound = {
              name                       = "AllowHttpsInbound"
              priority                   = 100
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              source_port_range          = "*"
              destination_port_range     = "443"
              source_address_prefix      = "VirtualNetwork"
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
