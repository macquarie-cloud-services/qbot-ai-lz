# Remote state for the QBot AI LZ platform connectivity layer.
# Supply the state key at init time:
#   terraform init -backend-config="key=qbot-platform-connectivity-aue.tfstate"
#   terraform init -reconfigure -backend-config="key=qbot-platform-connectivity-ause.tfstate"
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-qbot"
    storage_account_name = "qbottfstatenonprod"
    container_name       = "tfstateqbotplatform"
    use_azuread_auth     = true
    # key supplied at init time via -backend-config
  }
}
