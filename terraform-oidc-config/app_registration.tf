locals {
  app_registration_environments = local.security_option.oidc_with_app_registration ? { for env in var.environments : env => env } : {}
}

resource "azuread_application" "github_oidc" {
  for_each     = local.app_registration_environments
  display_name = "${var.prefix}-${each.value}"

  api {
    requested_access_token_version = 2
  }
}

resource "azuread_service_principal" "github_oidc" {
  for_each       = local.app_registration_environments
  application_id = azuread_application.github_oidc[each.value].application_id
}

resource "azuread_application_federated_identity_credential" "github_oidc" {
  for_each              = local.app_registration_environments
  application_object_id = azuread_application.github_oidc[each.value].object_id
  display_name          = "${var.azure_devops_organisation_target}-${var.azure_devops_project_target}-${each.value}"
  description           = "Deployments for ${var.azure_devops_organisation_target}/${var.azure_devops_project_target} for environment ${each.value}"
  audiences             = [local.default_audience_name]
  issuer                = azuredevops_serviceendpoint_azurerm.oidc[each.key].workload_identity_federation_issuer
  subject               = azuredevops_serviceendpoint_azurerm.oidc[each.key].workload_identity_federation_subject
}