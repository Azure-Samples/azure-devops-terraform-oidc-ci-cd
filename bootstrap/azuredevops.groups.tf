resource "azuredevops_group" "this" {
  scope        = local.azure_devops_project_id
  display_name = "approvers-${var.postfix}"
  description  = "Approvers for the Terraform Apply"
}

data "azuredevops_users" "this" {
  for_each       = var.approvers
  principal_name = each.value
}

locals {
  approvers = toset(flatten([for approver in data.azuredevops_users.this :
    [for user in approver.users : user.descriptor]
  ]))
}

resource "azuredevops_group_membership" "this" {
  group   = azuredevops_group.this.descriptor
  members = local.approvers
}
