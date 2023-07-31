variable "prefix" {
  type = string
}

variable "location" {
  type    = string
  default = "UK South"
}

variable "azure_devops_token" {
  type      = string
  sensitive = true
}

variable "azure_devops_organisation_prefix" {
  type    = string
  default = "https://dev.azure.com"
}

variable "azure_devops_organisation_target" {
  type = string
}

variable "azure_devops_project_target" {
  type = string
}

variable "github_organisation_template" {
  type    = string
  default = "Azure-Samples"
}

variable "github_repository_template" {
  type    = string
  default = "azure-devops-terraform-oidc-ci-cd"
}

variable "environments" {
  type    = list(string)
  default = ["dev", "test", "prod"]
}

variable "security_option" {
  type        = string
  default     = "self-hosted-agents-with-managed-identity"
  description = "There are three options `self-hosted-agents-with-managed-identity`, `oidc-with-user-assigned-managed-identity` and `oidc-with-app-registration`."
  validation {
    condition     = contains(["self-hosted-agents-with-managed-identity", "oidc-with-user-assigned-managed-identity", "oidc-with-app-registration"], var.security_option)
    error_message = "The security_option variable must be one of `self-hosted-agents-with-managed-identity`, `oidc-with-user-assigned-managed-identity` or `oidc-with-app-registration`."
  }
}

variable "use_legacy_issuer" {
  type    = bool
  default = true
}