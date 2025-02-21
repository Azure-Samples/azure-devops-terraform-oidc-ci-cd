resource "azuredevops_git_repository" "this" {
  depends_on = [azuredevops_environment.this]
  project_id = local.azure_devops_project_id
  name       = "${var.postfix}-demo"
  initialization {
    init_type = "Clean"
  }
}

resource "azuredevops_git_repository" "template" {
  depends_on = [azuredevops_environment.this]
  project_id = local.azure_devops_project_id
  name       = "${var.postfix}-demo-template"
  initialization {
    init_type = "Clean"
  }
}

locals {
  template_folder = "${path.module}../example-module"
  files = { for file in fileset(local.template_folder, "**") : file => {
    name    = file
    content = file("${local.template_folder}/${file}")
  } }

  pipeline_main_folder = "${path.module}../pipelines/main"
  pipeline_files = { for file in fileset(local.pipeline_main_folder, "**") : file => {
    name    = file
    content = file("${local.pipeline_main_folder}/${file}")
  } }

  main_repository_files = merge(local.files, local.pipeline_files)

  template_replacements = {
    environments = { for environment_key, environment_value in var.environments : environment_key => {
      name                          = environment_key
      display_name                  = environment_value.display_name
      variable_group_name           = environment_key
      agent_pool_configuration      = var.use_self_hosted_agents ? "name: ${azuredevops_agent_pool.this[0].name}" : "vmImage: ubuntu-latest"
      service_connection_name_plan  = "service_connection_${environment_key}-plan"
      service_connection_name_apply = "service_connection_${environment_key}-apply"
      environment_name              = environment_key
    } }
  }

  pipeline_template_folder = "${path.module}../pipelines/templates"
  pipeline_template_files = { for file in fileset(local.pipeline_template_folder, "**") : file => {
    name    = file
    content = templatefile("${local.pipeline_template_folder}/${file}", local.template_replacements)
  } }
}

resource "azuredevops_git_repository_file" "this" {
  for_each            = local.main_repository_files
  repository_id       = azuredevops_git_repository.this.id
  file                = each.key
  content             = each.value.content
  branch              = "refs/head/${azuredevops_git_repository.this.default_branch}"
  commit_message      = "[skip ci]"
  overwrite_on_create = true
}

resource "azuredevops_git_repository_file" "template" {
  for_each            = local.pipeline_template_files
  repository_id       = azuredevops_git_repository.template.id
  file                = each.key
  content             = each.value.content
  branch              = "refs/head/${azuredevops_git_repository.template.default_branch}"
  commit_message      = "[skip ci]"
  overwrite_on_create = true
}

resource "azuredevops_branch_policy_min_reviewers" "this" {
  depends_on = [azuredevops_git_repository_file.this]
  project_id = local.azure_devops_project_id

  enabled  = length(var.approvers) > 1
  blocking = true

  settings {
    reviewer_count                         = 1
    submitter_can_vote                     = false
    last_pusher_cannot_approve             = true
    allow_completion_with_rejects_or_waits = false
    on_push_reset_approved_votes           = true

    scope {
      repository_id  = azuredevops_git_repository.this.id
      repository_ref = azuredevops_git_repository.this.default_branch
      match_type     = "Exact"
    }
  }
}

resource "azuredevops_branch_policy_merge_types" "this" {
  depends_on = [azuredevops_git_repository_file.this]
  project_id = local.azure_devops_project_id

  enabled  = true
  blocking = true

  settings {
    allow_squash                  = true
    allow_rebase_and_fast_forward = false
    allow_basic_no_fast_forward   = false
    allow_rebase_with_merge       = false

    scope {
      repository_id  = azuredevops_git_repository.this.id
      repository_ref = azuredevops_git_repository.this.default_branch
      match_type     = "Exact"
    }
  }
}

resource "azuredevops_branch_policy_build_validation" "this" {
  depends_on = [azuredevops_git_repository_file.this]
  project_id = local.azure_devops_project_id

  enabled  = true
  blocking = true

  settings {
    display_name        = "Terraform Validation"
    build_definition_id = azuredevops_build_definition.this["ci"].id
    valid_duration      = 720

    scope {
      repository_id  = azuredevops_git_repository.this.id
      repository_ref = azuredevops_git_repository.this.default_branch
      match_type     = "Exact"
    }
  }
}


resource "azuredevops_branch_policy_min_reviewers" "template" {
  depends_on = [azuredevops_git_repository_file.template]
  project_id = local.azure_devops_project_id

  enabled  = length(var.approvers) > 1
  blocking = true

  settings {
    reviewer_count                         = 1
    submitter_can_vote                     = false
    last_pusher_cannot_approve             = true
    allow_completion_with_rejects_or_waits = false
    on_push_reset_approved_votes           = true

    scope {
      repository_id  = azuredevops_git_repository.template.id
      repository_ref = azuredevops_git_repository.template.default_branch
      match_type     = "Exact"
    }
  }
}

resource "azuredevops_branch_policy_merge_types" "template" {
  depends_on = [azuredevops_git_repository_file.template]
  project_id = local.azure_devops_project_id

  enabled  = true
  blocking = true

  settings {
    allow_squash                  = true
    allow_rebase_and_fast_forward = false
    allow_basic_no_fast_forward   = false
    allow_rebase_with_merge       = false

    scope {
      repository_id  = azuredevops_git_repository.template.id
      repository_ref = azuredevops_git_repository.template.default_branch
      match_type     = "Exact"
    }
  }
}