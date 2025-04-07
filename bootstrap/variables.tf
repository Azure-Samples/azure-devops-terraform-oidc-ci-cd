variable "location" {
  type        = string
  description = "The location/region where the resources will be created. Must be in the short form (e.g. 'uksouth')"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.location))
    error_message = "The location must only contain lowercase letters, numbers, and hyphens"
  }
  validation {
    condition     = length(var.location) <= 20
    error_message = "The location must be 20 characters or less"
  }
}

variable "resource_name_workload" {
  type        = string
  description = "The name segment for the workload"
  default     = "dema"
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.resource_name_workload))
    error_message = "The name segment for the workload must only contain lowercase letters and numbers"
  }
  validation {
    condition     = length(var.resource_name_workload) <= 4
    error_message = "The name segment for the workload must be 4 characters or less"
  }
}

variable "resource_name_environment" {
  type        = string
  description = "The name segment for the environment"
  default     = "mgt"
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.resource_name_environment))
    error_message = "The name segment for the environment must only contain lowercase letters and numbers"
  }
  validation {
    condition     = length(var.resource_name_environment) <= 4
    error_message = "The name segment for the environment must be 4 characters or less"
  }
}

variable "resource_name_sequence_start" {
  type        = number
  description = "The number to use for the resource names"
  default     = 1
  validation {
    condition     = var.resource_name_sequence_start >= 1 && var.resource_name_sequence_start <= 999
    error_message = "The number must be between 1 and 999"
  }
}

variable "resource_name_templates" {
  type        = map(string)
  description = "A map of resource names to use"
  default = {
    resource_group_state_name             = "rg-$${workload}-state-$${environment}-$${location}-$${sequence}"
    resource_group_agents_name            = "rg-$${workload}-agents-$${environment}-$${location}-$${sequence}"
    resource_group_identity_name          = "rg-$${workload}-identity-$${environment}-$${location}-$${sequence}"
    virtual_network_name                  = "vnet-$${workload}-$${environment}-$${location}-$${sequence}"
    network_security_group_name           = "nsg-$${workload}-$${environment}-$${location}-$${sequence}"
    nat_gateway_name                      = "nat-$${workload}-$${environment}-$${location}-$${sequence}"
    nat_gateway_public_ip_name            = "pip-nat-$${workload}-$${environment}-$${location}-$${sequence}"
    storage_account_name                  = "sto$${workload}$${environment}$${location}$${sequence}$${uniqueness}"
    storage_account_private_endpoint_name = "pe-sto-$${workload}-$${environment}-$${location}-$${sequence}"
    agent_compute_postfix_name            = "$${workload}-$${environment}-$${location}-$${sequence}"
    container_instance_prefix_name        = "aci-$${workload}-$${environment}-$${location}"
    container_registry_name               = "acr$${workload}$${environment}$${location}$${sequence}$${uniqueness}"
    project_name                          = "$${workload}-$${environment}"
    repository_main_name                  = "$${workload}-$${environment}-main"
    repository_template_name              = "$${workload}-$${environment}-template"
    agent_pool_name                       = "agent-pool-$${workload}-$${environment}"
    group_name                            = "group-$${workload}-$${environment}-approvers"
  }
}

variable "environments" {
  type = map(object({
    display_order                                = number
    display_name                                 = string
    has_approval                                 = optional(bool, false)
    dependent_environment                        = optional(string, "")
    resource_group_create                        = optional(bool, true)
    resource_group_name_template                 = optional(string, "rg-$${workload}-env-$${environment}-$${location}-$${sequence}")
    user_assigned_managed_identity_name_template = optional(string, "uami-$${workload}-$${environment}-$${type}-$${location}-$${sequence}")
  }))
  default = {
    dev = {
      display_order = 1
      display_name  = "Development"
    }
    test = {
      display_order         = 2
      display_name          = "Test"
      dependent_environment = "dev"
    }
    prod = {
      display_order         = 3
      display_name          = "Production"
      has_approval          = true
      dependent_environment = "test"
    }
  }
}

variable "personal_access_token" {
  type      = string
  sensitive = true
}

variable "organization_name_prefix" {
  type    = string
  default = "https://dev.azure.com"
}

variable "organization_name" {
  type = string
}

variable "azure_devops_project" {
  type    = string
  default = null
}

variable "azure_devops_create_project" {
  type    = bool
  default = true
}

variable "use_self_hosted_agents" {
  type    = bool
  default = true
}

variable "self_hosted_agent_type" {
  type    = string
  default = "azure_container_instance"
  validation {
    condition     = contains(["azure_container_app", "azure_container_instance"], var.self_hosted_agent_type)
    error_message = "self_hosted_agent_type must be either 'azure_container_app' or 'azure_container_instance'."
  }
}

variable "address_space" {
  type        = string
  description = "The virtual network address space"
  default     = "10.0.0.0/24"
}

variable "subnets_and_sizes" {
  type        = map(number)
  description = "The size of the subnets"
  default = {
    agents            = 27
    private_endpoints = 29
  }
}

variable "approvers" {
  type    = map(string)
  default = {}
}

variable "example_module_path" {
  type    = string
  default = "../example-module"
}

variable "repository_postfix" {
  type    = string
  default = "demo"
}

variable "repository_postfix_template" {
  type    = string
  default = "demo-template"
}
