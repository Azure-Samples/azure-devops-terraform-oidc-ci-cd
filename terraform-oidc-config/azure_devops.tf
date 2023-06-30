resource "random_pet" "example" {

}

data "azuredevops_project" "example" {
  name = var.azure_devops_project_target
}

resource "azuredevops_environment" "example" {
  for_each   = { for env in var.environments : env => env }
  name       = each.value
  project_id = data.azuredevops_project.example.id
}

resource "azuredevops_git_repository" "example" {
  depends_on = [azuredevops_environment.example]
  project_id = data.azuredevops_project.example.id
  name       = "${var.prefix}-${random_pet.example.id}"
  initialization {
    init_type   = "Import"
    source_type = "Git"
    source_url  = "https://github.com/${var.github_organisation_template}/${var.github_repository_template}.git"
  }
}

resource "azuredevops_build_definition" "oidc" {
  count      = local.security_option.oidc_with_app_registration || local.security_option.oidc_with_user_assigned_managed_identity ? 1 : 0
  project_id = data.azuredevops_project.example.id
  name       = "Run Terraform with OpenID Connect"

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.example.id
    branch_name = azuredevops_git_repository.example.default_branch
    yml_path    = "pipelines/oidc.yml"
  }
}

resource "azuredevops_build_definition" "mi" {
  count      = local.security_option.self_hosted_agents_with_managed_identity ? 1 : 0
  project_id = data.azuredevops_project.example.id
  name       = "Run Terraform with Managed Identity"

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.example.id
    branch_name = azuredevops_git_repository.example.default_branch
    yml_path    = "pipelines/mi.yml"
  }
}

resource "azuredevops_pipeline_authorization" "oidc" {
  for_each    = local.security_option.oidc_with_app_registration || local.security_option.oidc_with_user_assigned_managed_identity ? { for env in var.environments : env => env } : {}
  project_id  = data.azuredevops_project.example.id
  resource_id = azuredevops_environment.example[each.value].id
  type        = "environment"
  pipeline_id = azuredevops_build_definition.oidc[0].id
}

resource "azuredevops_pipeline_authorization" "mi" {
  for_each    = local.security_option.self_hosted_agents_with_managed_identity ? { for env in var.environments : env => env } : {}
  project_id  = data.azuredevops_project.example.id
  resource_id = azuredevops_environment.example[each.value].id
  type        = "environment"
  pipeline_id = azuredevops_build_definition.mi[0].id
}

resource "azuredevops_branch_policy_build_validation" "oidc" {
  count      = local.security_option.oidc_with_app_registration || local.security_option.oidc_with_user_assigned_managed_identity ? 1 : 0
  project_id = data.azuredevops_project.example.id

  enabled  = true
  blocking = true

  settings {
    display_name        = "Terraform validation policy with OpenID Connect"
    build_definition_id = azuredevops_build_definition.oidc[0].id
    valid_duration      = 720

    scope {
      repository_id  = azuredevops_git_repository.example.id
      repository_ref = azuredevops_git_repository.example.default_branch
      match_type     = "Exact"
    }

    scope {
      match_type = "DefaultBranch"
    }
  }
}

resource "azuredevops_branch_policy_build_validation" "mi" {
  count      = local.security_option.self_hosted_agents_with_managed_identity ? 1 : 0
  project_id = data.azuredevops_project.example.id

  enabled  = true
  blocking = true

  settings {
    display_name        = "Terraform validation policy with Managed Identity"
    build_definition_id = azuredevops_build_definition.mi[0].id
    valid_duration      = 720

    scope {
      repository_id  = azuredevops_git_repository.example.id
      repository_ref = azuredevops_git_repository.example.default_branch
      match_type     = "Exact"
    }

    scope {
      match_type = "DefaultBranch"
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
    name  = "AZURE_RESOURCE_GROUP_NAME"
    value = azurerm_resource_group.example[each.value].name
  }

  variable {
    name  = "BACKEND_AZURE_RESOURCE_GROUP_NAME"
    value = azurerm_resource_group.state.name
  }

  variable {
    name  = "BACKEND_AZURE_STORAGE_ACCOUNT_NAME"
    value = azurerm_storage_account.example.name
  }

  variable {
    name  = "BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME"
    value = azurerm_storage_container.example[each.value].name
  }
}

resource "terraform_data" "service_connection_oidc" {
  for_each     = local.security_option.oidc_with_user_assigned_managed_identity || local.security_option.oidc_with_app_registration ? { for env in var.environments : env => env } : {}
  triggers_replace = [ azurerm_user_assigned_identity.example[each.value].id ]
  input = {
    service_connection_name = "service_connection_${each.value}"
    client_id               = local.security_option.oidc_with_app_registration ? azuread_application.github_oidc[each.value].application_id : azurerm_user_assigned_identity.example[each.value].client_id
    tenant_id               = data.azurerm_client_config.current.tenant_id
    subscription_id         = data.azurerm_client_config.current.subscription_id
    subscription_name       = data.azurerm_subscription.current.display_name
    project_id              = data.azuredevops_project.example.id
    project_name            = data.azuredevops_project.example.name
    access_token            = var.azure_devops_token
    organization_url        = "${var.azure_devops_organisation_prefix}/${var.azure_devops_organisation_target}"
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-Command"]
    command     = "./scripts/create_service_connection.ps1 -serviceConnectionName \"${self.input.service_connection_name}\" -clientId \"${self.input.client_id}\" -tenantId \"${self.input.tenant_id}\" -subscriptionId \"${self.input.subscription_id}\" -subscriptionName \"${self.input.subscription_name}\" -projectId \"${self.input.project_id}\" -projectName \"${self.input.project_name}\" -accessToken \"${self.input.access_token}\" -organizationUrl \"${self.input.organization_url}\" "
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["pwsh", "-Command"]
    command     = "./scripts/create_service_connection.ps1 -action=\"Destroy\" -serviceConnectionName \"${self.input.service_connection_name}\" -clientId \"${self.input.client_id}\" -tenantId \"${self.input.tenant_id}\" -subscriptionId \"${self.input.subscription_id}\" -subscriptionName \"${self.input.subscription_name}\" -projectId \"${self.input.project_id}\" -projectName \"${self.input.project_name}\" -accessToken \"${self.input.access_token}\" -organizationUrl \"${self.input.organization_url}\" "
  }
}

resource "terraform_data" "service_connection_managed_identity" {
  for_each     = local.security_option.self_hosted_agents_with_managed_identity ? { for env in var.environments : env => env } : {}
  triggers_replace = [ azurerm_user_assigned_identity.example[each.value].id ]
  input = {
    service_connection_name = "service_connection_mi_${each.value}"
    tenant_id               = data.azurerm_client_config.current.tenant_id
    subscription_id         = data.azurerm_client_config.current.subscription_id
    subscription_name       = data.azurerm_subscription.current.display_name
    project_id              = data.azuredevops_project.example.id
    project_name            = data.azuredevops_project.example.name
    access_token            = var.azure_devops_token
    organization_url        = "${var.azure_devops_organisation_prefix}/${var.azure_devops_organisation_target}"
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-Command"]
    command     = "./scripts/create_service_connection.ps1 -serviceConnectionType \"ManagedIdentity\" -serviceConnectionName \"${self.input.service_connection_name}\" -tenantId \"${self.input.tenant_id}\" -subscriptionId \"${self.input.subscription_id}\" -subscriptionName \"${self.input.subscription_name}\" -projectId \"${self.input.project_id}\" -projectName \"${self.input.project_name}\" -accessToken \"${self.input.access_token}\" -organizationUrl \"${self.input.organization_url}\" "
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["pwsh", "-Command"]
    command     = "./scripts/create_service_connection.ps1 -action=\"Destroy\" -serviceConnectionType \"ManagedIdentity\" -serviceConnectionName \"${self.input.service_connection_name}\" -tenantId \"${self.input.tenant_id}\" -subscriptionId \"${self.input.subscription_id}\" -subscriptionName \"${self.input.subscription_name}\" -projectId \"${self.input.project_id}\" -projectName \"${self.input.project_name}\" -accessToken \"${self.input.access_token}\" -organizationUrl \"${self.input.organization_url}\" "
  }
}

data "azuredevops_serviceendpoint_azurerm" "oidc" {
  for_each = local.security_option.oidc_with_user_assigned_managed_identity || local.security_option.oidc_with_app_registration ? { for env in var.environments : env => env } : {}
  depends_on = [
    terraform_data.service_connection_oidc
  ]
  project_id            = data.azuredevops_project.example.id
  service_endpoint_name = "service_connection_${each.value}"
}

data "azuredevops_serviceendpoint_azurerm" "mi" {
  for_each = local.security_option.self_hosted_agents_with_managed_identity ? { for env in var.environments : env => env } : {}
  depends_on = [
    terraform_data.service_connection_managed_identity
  ]
  project_id            = data.azuredevops_project.example.id
  service_endpoint_name = "service_connection_mi_${each.value}"
}

resource "azuredevops_pipeline_authorization" "oidc_endpoint" {
  for_each    = local.security_option.oidc_with_app_registration || local.security_option.oidc_with_user_assigned_managed_identity ? { for env in var.environments : env => env } : {}
  project_id  = data.azuredevops_project.example.id
  resource_id = data.azuredevops_serviceendpoint_azurerm.oidc[each.value].service_endpoint_id 
  type        = "endpoint"
  pipeline_id = azuredevops_build_definition.oidc[0].id
}

resource "azuredevops_pipeline_authorization" "mi_endpoint" {
  for_each    = local.security_option.self_hosted_agents_with_managed_identity ? { for env in var.environments : env => env } : {}
  project_id  = data.azuredevops_project.example.id
  resource_id = data.azuredevops_serviceendpoint_azurerm.mi[each.value].service_endpoint_id
  type        = "environment"
  pipeline_id = azuredevops_build_definition.mi[0].id
}