data "azuredevops_project" "this" {
  count = var.azure_devops_create_project ? 0 : 1
  name  = var.azure_devops_project
}

resource "azuredevops_project" "this" {
  count = var.azure_devops_create_project ? 1 : 0
  name  = var.azure_devops_project
}

locals {
  azure_devops_project_id = var.azure_devops_create_project ? azuredevops_project.this[0].id : data.azuredevops_project.this[0].id
}

resource "azuredevops_environment" "this" {
  for_each   = var.environments
  name       = each.key
  project_id = local.azure_devops_project_id
}
