#--------------------------------------------------------------
# ai-networking — Provider Requirements
#
# This module uses two azurerm provider instances:
#   azurerm     — default, scoped to the spoke subscription.
#                 Used for all spoke resources (NSGs, spoke VNet, spoke→hub peering).
#   azurerm.hub — alias, scoped to the hub subscription.
#                 Used only for hub-side resources created from the spoke:
#                   • azurerm_virtual_network_peering.hub_to_spoke
#                   • azurerm_private_dns_zone_virtual_network_link.spoke_links
#
# When hub and spoke share the same subscription both providers can point
# at the same subscription_id — Terraform handles this transparently.
#
# The calling root module (landing-zones/ai) must pass both providers:
#   providers = {
#     azurerm     = azurerm
#     azurerm.hub = azurerm.hub
#   }
#--------------------------------------------------------------
terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 4.0"
      configuration_aliases = [azurerm.hub]
    }
  }
}
