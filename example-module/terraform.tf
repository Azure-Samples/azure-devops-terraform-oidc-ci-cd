terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }

  }
  backend "azurerm" {}
}

provider "azurerm" {
  resource_provider_registrations = "core"
  features {}
}
