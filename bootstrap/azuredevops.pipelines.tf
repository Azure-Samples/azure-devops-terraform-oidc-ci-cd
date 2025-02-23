locals {
  pipelines = {
    ci = {
      name      = "01 - Conitnuous Integration"
      file_path = "ci.yaml"
    }
    cd = {
      name      = "02 - Continuous Delivery"
      file_path = "cd.yaml"
    }
  }
  pipelines_by_environment = { for environment_split in flatten([for env_key, env_value in var.environments : [
    for pipeline_key, pipeline_value in local.pipelines : {
      composite_key = "${env_key}-${pipeline_key}"
      environment   = env_key
      pipeline      = pipeline_key
    }
  ]]) : environment_split.composite_key => environment_split }

  pipelines_by_service_connection = { for environment_split in flatten([for env_key, env_value in local.environment_split : [
    for pipeline_key, pipeline_value in local.pipelines : {
      composite_key      = "${env_key}-${pipeline_key}"
      service_connection = env_key
      pipeline           = pipeline_key
      is_valid           = env_value.type == "plan" || env_value.type == "apply" && pipeline_key == "cd"
    }
  ]]) : environment_split.composite_key => environment_split if environment_split.is_valid }
}

resource "azuredevops_build_definition" "this" {
  for_each   = local.pipelines
  project_id = local.azure_devops_project_id
  name       = each.value.name

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.this.id
    branch_name = azuredevops_git_repository.this.default_branch
    yml_path    = each.value.file_path
  }
}

resource "azuredevops_pipeline_authorization" "service_connection" {
  for_each    = local.pipelines_by_service_connection
  project_id  = local.azure_devops_project_id
  resource_id = azuredevops_serviceendpoint_azurerm.this[each.value.service_connection].id
  type        = "endpoint"
  pipeline_id = azuredevops_build_definition.this[each.value.pipeline].id
}

resource "azuredevops_pipeline_authorization" "environment" {
  for_each    = local.pipelines_by_environment
  project_id  = local.azure_devops_project_id
  resource_id = azuredevops_environment.this[each.value.environment].id
  type        = "environment"
  pipeline_id = azuredevops_build_definition.this[each.value.pipeline].id
}

resource "azuredevops_pipeline_authorization" "agent_pool" {
  for_each    = var.use_self_hosted_agents ? local.pipelines : {}
  project_id  = local.azure_devops_project_id
  resource_id = azuredevops_agent_queue.this[0].id
  type        = "queue"
  pipeline_id = azuredevops_build_definition.this[each.key].id
}
