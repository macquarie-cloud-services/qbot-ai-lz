# Remote state for the QBot AI Landing Zone.
# Supply the state key at init time:
#   terraform init -backend-config="key=lz-ai-dev-aue.tfstate"
#   terraform init -reconfigure -backend-config="key=lz-ai-dev-ause.tfstate"
#   terraform init -reconfigure -backend-config="key=lz-ai-prod-aue.tfstate"
#   terraform init -reconfigure -backend-config="key=lz-ai-prod-ause.tfstate"
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-qbot"
    storage_account_name = "qbottfstatenonprod"
    container_name       = "tfstateqbotai"
    use_azuread_auth     = true
    # key supplied at init time via -backend-config
  }
}
