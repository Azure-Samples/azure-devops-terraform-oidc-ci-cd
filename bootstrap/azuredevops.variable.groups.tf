
resource "azuredevops_variable_group" "this" {
  for_each     = var.environments
  project_id   = local.azure_devops_project_id
  name         = each.key
  description  = "Variable Group for ${each.value.display_name}"
  allow_access = true

  variable {
    name  = "ADDITIONAL_ENVIRONMENT_VARIABLES"
    value = jsonencode({
       TF_VAR_resource_group_name = module.resource_group_environments[each.key].name
    })
  }

  variable {
    name  = "BACKEND_AZURE_RESOURCE_GROUP_NAME"
    value = module.resource_group["state"].name
  }

  variable {
    name  = "BACKEND_AZURE_STORAGE_ACCOUNT_NAME"
    value = module.storage_account.name
  }

  variable {
    name  = "BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME"
    value = each.key
  }
}