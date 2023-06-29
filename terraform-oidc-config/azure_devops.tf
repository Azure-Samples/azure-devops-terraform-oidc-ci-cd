resource "random_pet" "example" {

}

data "azuredevops_project" "example" {
  name = var.azure_devops_project_target
}


resource "azuredevops_git_repository" "example" {
  project_id = data.azuredevops_project.example.id
  name       = "${var.prefix}-${random_pet.example.id}"
  initialization {
    init_type   = "Import"
    source_type = "Git"
    source_url  = "https://github.com/${var.github_organisation_template}/${var.github_repository_template}.git"
  }
}

resource "azuredevops_environment" "example" {
  for_each   = { for env in var.environments : env => env }
  name       = each.value
  project_id = data.azuredevops_project.example.id
}

resource "azuredevops_build_definition" "example" {
  project_id = data.azuredevops_project.example.id
  name       = "Run Terraform with OpenID Connect"

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.example.id
    branch_name = azuredevops_git_repository.example.default_branch
    yml_path    = "pipelines/main.yml"
  }
}

resource "azuredevops_pipeline_authorization" "example" {
  for_each   = { for env in var.environments : env => env }
  project_id  = data.azuredevops_project.example.id
  resource_id = azuredevops_environment.example[each.value].id
  type        = "environment"
  pipeline_id = azuredevops_build_definition.example.id
}

resource "azuredevops_branch_policy_build_validation" "example" {
  project_id = data.azuredevops_project.example.id

  enabled  = true
  blocking = true

  settings {
    display_name        = "Terraform validation policy"
    build_definition_id = azuredevops_build_definition.example.id
    valid_duration      = 720

    scope {
      repository_id  = azuredevops_git_repository.example.id
      repository_ref = azuredevops_git_repository.example.default_branch
      match_type     = "Exact"
    }

    scope {
      match_type     = "DefaultBranch"
    }
  }
}

resource "azuredevops_variable_group" "example" {
  for_each     = { for env in var.environments : env => env }
  project_id   = data.azuredevops_project.example.id
  name         = each.value
  description  = "Example Variable Group for ${each.value}"
  allow_access = true

  variable {
    name         = "AZURE_RESOURCE_GROUP_NAME"
    value = azurerm_resource_group.example[each.value].name
  }

  variable {
    name         = "BACKEND_AZURE_RESOURCE_GROUP_NAME"
    value = azurerm_resource_group.state.name
  }

  variable {
    name         = "BACKEND_AZURE_STORAGE_ACCOUNT_NAME"
    value = azurerm_storage_account.example.name
  }

  variable {
    name         = "BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME"
    value = azurerm_storage_container.example[each.value].name
  }

  variable {
    name         = "SERVICE_CONNECTION_NAME"
    value = "service_connection_${each.value}"
  }
}