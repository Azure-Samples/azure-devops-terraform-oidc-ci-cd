locals {
  default_audience_name         = "api://AzureADTokenExchange"
  azure_devops_organization_url = "${var.azure_devops_organization_prefix}/${var.azure_devops_organization}"
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
      composite_key     = "${env_key}-${split_key}"
      environment       = env_key
      type              = split_key
      required_template = split_key == local.environment_split_type.plan ? "ci-template.yaml" : "cd-template.yaml"
    }
  ]]) : environment_split.composite_key => environment_split }
}

locals {
  my_ip_address_split = split(".", data.http.ip.response_body)
  my_cidr_slash_24    = "${join(".", slice(local.my_ip_address_split, 0, 3))}.0/24" # We are using a wider CIDR range for demo purposes as many users may not have a static IP, but very likely an address in the same /24
}

locals {
  address_space_split           = split("/", var.address_space)
  address_space_start_ip        = local.address_space_split[0]
  address_space_size            = tonumber(local.address_space_split[1])
  order_by_size                 = { for key, value in var.subnets_and_sizes : "${format("%03s", value)}||${key}" => value }
  virtual_network_address_space = "${local.address_space_start_ip}/${local.address_space_size}"
  subnet_keys                   = keys(local.order_by_size)
  subnet_new_bits               = [for size in values(local.order_by_size) : size - local.address_space_size]
  cidr_subnets                  = cidrsubnets(local.virtual_network_address_space, local.subnet_new_bits...)
  subnets                       = { for key, value in local.order_by_size : split("||", key)[1] => local.cidr_subnets[index(local.subnet_keys, key)] }
  subnet_delegations = { for key, value in var.subnets_and_sizes : key => key == "agents" ? [
    {
      name = "Microsoft.App/environments"
      service_delegation = {
        name = "Microsoft.App/environments"
      }
    }
  ] : [] }
}