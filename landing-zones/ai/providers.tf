terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Default provider — scoped to the spoke subscription.
# All landing zone resources (NSGs, spoke VNet, App Services, etc.) use this.
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy               = false
      recover_soft_deleted_key_vaults            = true
      purge_soft_deleted_secrets_on_destroy      = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = false
    }
  }
  subscription_id = var.spoke_subscription_id
}

# Hub provider alias — scoped to the hub/connectivity subscription.
# Used only for hub-side resources created from the spoke:
#   • hub→spoke VNet peering  (azurerm_virtual_network_peering.hub_to_spoke)
#   • DNS zone VNet links     (azurerm_private_dns_zone_virtual_network_link.spoke_links)
#
# When hub and spoke share the same subscription set both to the same value.
provider "azurerm" {
  alias = "hub"
  features {}
  subscription_id = var.hub_subscription_id
}

provider "azapi" {
  subscription_id = var.spoke_subscription_id
}
