resource "azuredevops_agent_pool" "this" {
  count          = var.use_self_hosted_agents ? 1 : 0
  name           = "ado-agent-${lower(var.postfix)}"
  auto_provision = false
  auto_update    = true
}

resource "azuredevops_agent_queue" "this" {
  count         = var.use_self_hosted_agents ? 1 : 0
  project_id    = local.azure_devops_project_id
  agent_pool_id = azuredevops_agent_pool.this[0].id
}
