terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.30.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.30.0"
    }
  }
  backend "azurerm" {
    key = "terraform.tfstate"
    use_oidc = true
  }
}

provider "azurerm" {
  use_oidc = true
  skip_provider_registration = true
  features {}
}

provider "azuread" {
}

data "azurerm_client_config" "current" {}