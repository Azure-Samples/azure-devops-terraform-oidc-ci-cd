terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.7"
    }
  }
}

provider "azuredevops" {
  org_service_url       = local.organization_name_url
  personal_access_token = var.personal_access_token
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    storage {
      data_plane_available = false
    }
  }
  storage_use_azuread = true
}
