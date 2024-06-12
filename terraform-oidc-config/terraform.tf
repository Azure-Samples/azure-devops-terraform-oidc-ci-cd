terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.107"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.30"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.9.0"
    }
  }
}

provider "azuredevops" {
  org_service_url       = "${var.azure_devops_organisation_prefix}/${var.azure_devops_organisation_target}"
  personal_access_token = var.azure_devops_token
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  storage_use_azuread = true
}

provider "azuread" {
}