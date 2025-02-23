resource "azuredevops_serviceendpoint_azurerm" "this" {
  for_each                               = local.environment_split
  project_id                             = local.azure_devops_project_id
  service_endpoint_name                  = "service-connection-${each.key}"
  description                            = "Managed by Terraform"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  credentials {
    serviceprincipalid = module.user_assigned_managed_identity[each.key].client_id
  }
  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_client_config.current.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name
}

locals {
  environments_with_approvals = { for key, value in var.environments : key => value if value.has_approval }
}

resource "azuredevops_check_approval" "this" {
  for_each             = length(var.approvers) == 0 ? {} : local.environments_with_approvals
  project_id           = local.azure_devops_project_id
  target_resource_id   = azuredevops_serviceendpoint_azurerm.this["${each.key}-apply"].id
  target_resource_type = "endpoint"

  requester_can_approve = length(var.approvers) == 1
  approvers = [
    azuredevops_group.this.origin_id
  ]

  timeout = 43200
}

resource "azuredevops_check_exclusive_lock" "service_connection" {
  for_each             = local.environment_split
  project_id           = local.azure_devops_project_id
  target_resource_id   = azuredevops_serviceendpoint_azurerm.this[each.key].id
  target_resource_type = "endpoint"
  timeout              = 43200
}

resource "azuredevops_check_required_template" "this" {
  for_each             = local.environment_split
  project_id           = local.azure_devops_project_id
  target_resource_id   = azuredevops_serviceendpoint_azurerm.this[each.key].id
  target_resource_type = "endpoint"

  dynamic "required_template" {
    for_each = { for template in each.value.required_templates : template => template }
    content {
      repository_type = "azuregit"
      repository_name = "${var.azure_devops_project}/${azuredevops_git_repository.template.name}"
      repository_ref  = local.default_branch
      template_path   = required_template.value
    }
  }
}
