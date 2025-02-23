variable "postfix" {
  type = string
}

variable "location" {
  type    = string
  default = "UK South"
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
  type = string
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

variable "environments" {
  type = map(object({
    display_order         = number
    display_name          = string
    has_approval          = optional(bool, false)
    dependent_environment = optional(string, "")
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
