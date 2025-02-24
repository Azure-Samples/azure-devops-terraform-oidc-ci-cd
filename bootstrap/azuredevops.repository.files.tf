locals {
  environment_replacements = { for environment_key, environment_value in var.environments : "${format("%03s", environment_value.display_order)}-${environment_key}" => {
    name                          = lower(replace(environment_key, "-", ""))
    display_name                  = environment_value.display_name
    variable_group_name           = environment_key
    agent_pool_type               = var.use_self_hosted_agents ? "self-hosted" : "microsoft-hosted"
    agent_pool_name               = var.use_self_hosted_agents ? "${azuredevops_agent_pool.this[0].name}" : "ubuntu-latest"
    service_connection_name_plan  = "service-connection-${environment_key}-plan"
    service_connection_name_apply = "service-connection-${environment_key}-apply"
    environment_name              = environment_key
    dependent_environment         = environment_value.dependent_environment
  } }

  template_folder = "${path.module}/${var.example_module_path}"
  files = { for file in fileset(local.template_folder, "**") : file => {
    name    = file
    content = file("${local.template_folder}/${file}")
  } }

  pipeline_main_replacements = {
    environments                     = local.environment_replacements
    project_name                     = var.azure_devops_project
    repository_name_templates        = azuredevops_git_repository.template.name
    cd_template_path                 = "cd-template.yaml"
    ci_template_path                 = "ci-template.yaml"
    root_module_folder_relative_path = "."
  }

  pipeline_main_folder = "${path.module}/../pipelines/main"
  pipeline_main_files = { for file in fileset(local.pipeline_main_folder, "**") : file => {
    name    = file
    content = templatefile("${local.pipeline_main_folder}/${file}", local.pipeline_main_replacements)
  } }

  main_repository_files = merge(local.files, local.pipeline_main_files)

  pipeline_template_replacements = {
    environments = local.environment_replacements
  }

  pipeline_template_folder = "${path.module}/../pipelines/templates"
  pipeline_template_files = { for file in fileset(local.pipeline_template_folder, "**") : file => {
    name    = file
    content = file("${local.pipeline_template_folder}/${file}")
  } }
}

resource "azuredevops_git_repository_file" "this" {
  for_each            = local.main_repository_files
  repository_id       = azuredevops_git_repository.this.id
  file                = each.key
  content             = each.value.content
  branch              = local.default_branch
  commit_message      = "[skip ci]"
  overwrite_on_create = true
}

resource "azuredevops_git_repository_file" "template" {
  for_each            = local.pipeline_template_files
  repository_id       = azuredevops_git_repository.template.id
  file                = each.key
  content             = each.value.content
  branch              = local.default_branch
  commit_message      = "[skip ci]"
  overwrite_on_create = true
}
