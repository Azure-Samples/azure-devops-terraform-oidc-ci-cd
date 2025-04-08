data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.0"
}