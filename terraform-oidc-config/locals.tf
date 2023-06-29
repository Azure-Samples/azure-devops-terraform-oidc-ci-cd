locals {
  default_audience_name = "api://AzureADTokenExchange"
  github_issuer_url     = "https://app.vstoken.visualstudio.com"
  security_option = {
    self_hosted_agents_with_managed_identity = var.security_option == "self-hosted-agents-with-managed-identity"
    oidc_with_user_assigned_managed_identity = var.security_option == "oidc-with-user-assigned-managed-identity"
    oidc_with_app_registration               = var.security_option == "oidc-with-app-registration"
  }
}