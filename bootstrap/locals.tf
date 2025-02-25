locals {
  default_audience_name = "api://AzureADTokenExchange"
  organization_name_url = "${var.organization_name_prefix}/${var.organization_name}"
}

locals {
  storage_account_name = "stotfstate${lower(replace(var.postfix, "-", ""))}"
  virtual_network_name = "vnet-${lower(var.postfix)}"
}

locals {
  environment_split_type = {
    plan  = "plan"
    apply = "apply"
  }
  environment_split = { for environment_split in flatten([for env_key, env_value in var.environments : [
    for split_key, split_value in local.environment_split_type : {
      composite_key      = "${env_key}-${split_key}"
      environment        = env_key
      type               = split_key
      required_templates = split_key == local.environment_split_type.plan ? ["ci-template.yaml", "cd-template.yaml"] : ["cd-template.yaml"]
    }
  ]]) : environment_split.composite_key => environment_split }
}

locals {
  repository_name          = "${var.postfix}-${var.repository_postfix}"
  repository_name_template = "${var.postfix}-${var.repository_postfix_template}"
}