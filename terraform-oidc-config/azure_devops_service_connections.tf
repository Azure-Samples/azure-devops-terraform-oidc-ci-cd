resource "terraform_data" "service_connection_oidc" {
  for_each         = local.oidc_environments
  triggers_replace = [azurerm_user_assigned_identity.example[each.value].id]
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
  for_each         = local.mi_environments
  triggers_replace = [azurerm_user_assigned_identity.example[each.value].id]
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
  for_each = local.oidc_environments
  depends_on = [
    terraform_data.service_connection_oidc
  ]
  project_id            = data.azuredevops_project.example.id
  service_endpoint_name = "service_connection_${each.value}"
}

data "azuredevops_serviceendpoint_azurerm" "mi" {
  for_each = local.mi_environments
  depends_on = [
    terraform_data.service_connection_managed_identity
  ]
  project_id            = data.azuredevops_project.example.id
  service_endpoint_name = "service_connection_mi_${each.value}"
}

resource "azuredevops_pipeline_authorization" "oidc_endpoint" {
  for_each    = local.oidc_environments
  project_id  = data.azuredevops_project.example.id
  resource_id = data.azuredevops_serviceendpoint_azurerm.oidc[each.value].service_endpoint_id
  type        = "endpoint"
  pipeline_id = azuredevops_build_definition.oidc[0].id
}

resource "azuredevops_pipeline_authorization" "mi_endpoint" {
  for_each    = local.mi_environments
  project_id  = data.azuredevops_project.example.id
  resource_id = data.azuredevops_serviceendpoint_azurerm.mi[each.value].service_endpoint_id
  type        = "endpoint"
  pipeline_id = azuredevops_build_definition.mi[0].id
}