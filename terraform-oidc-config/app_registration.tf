resource "azuread_application" "github_oidc" {
  for_each     = var.use_managed_identity ? {} : { for env in var.environments : env => env }
  display_name = "${var.prefix}-${each.value}"

  api {
    requested_access_token_version = 2
  }
}

resource "azuread_service_principal" "github_oidc" {
  for_each       = var.use_managed_identity ? {} : { for env in var.environments : env => env }
  application_id = azuread_application.github_oidc[each.value].application_id
}

resource "azuread_application_federated_identity_credential" "github_oidc" {
  for_each              = var.use_managed_identity ? {} : { for env in var.environments : env => env }
  application_object_id = azuread_application.github_oidc[each.value].object_id
  display_name          = "${var.azure_devops_organisation_target}-${var.azure_devops_project_target}-${each.value}"
  description           = "Deployments for ${var.azure_devops_organisation_target}/${var.azure_devops_project_target} for environment ${each.value}"
  audiences             = [local.default_audience_name]
  issuer                = local.github_issuer_url
  subject               = "sc://${var.azure_devops_organisation_target}/${var.azure_devops_project_target}/service_connection_${each.value}"
}