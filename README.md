---
page_type: sample
languages:
- terraform
- hcl
- yaml
name: Using Azure DevOps Pipelines Workload identity federation (OIDC) or Managed Identity with Azure for Terraform Deployments
description: A sample showing how to configure Azure DevOps Workload identity federation (OIDC) or Managed Identity connection to Azure with Terraform and then use that configuration to deploy resources with Terraform.
products:
- azure
- azure-devops
urlFragment: azure-devops-terraform-oidc-ci-cd
---

# Using Azure DevOps Pipelines Workload identity federation (OIDC) or Managed Identity with Azure for Terraform Deployments

This is a two part sample. The first part demonstrates how to configure Azure and Azure DevOps for credential free deployment with Terraform. The second part demonstrates an end to end Continuous Delivery Pipeline for Terraform.

## Content

| File/folder | Description |
|-------------|-------------|
| `bootstrap` | The Terraform to configure Azure and Azure DevOps ready for Workload identity federation (OIDC) or Managed Identity authenticaton. |
| `example-module` | Some Terraform with Azure Resources for the demo to deploy. |
| `pipelines` | The templated Azure DevOps Pipelines for the demo. |
| `.gitignore` | Define what to ignore at commit time. |
| `CHANGELOG.md` | List of changes to the sample. |
| `CONTRIBUTING.md` | Guidelines for contributing to the sample. |
| `README.md` | This README file. |
| `LICENSE.md` | The license for the sample. |

## Features

This sample includes the following features:

* Setup 3 Azure User Assigned Managed Identities with Federation ready for Azure DevOps Workload identity federation (OIDC).
* Setup an Azure Storage Account for State file management.
* Setup Azure DevOps repository and environments ready to deploy Terraform with Workload identity federation (OIDC).
* Run a Continuous Delivery pipeline for Terraform using Workload identity federation (OIDC) auth for state and deploying resources to Azure.
* Run a Pull Request workflow with some basic static analysis.

## Getting Started

### Prerequisites

- HashiCorp Terraform CLI: [Download](https://www.terraform.io/downloads)
- Azure CLI: [Download](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli#install-or-update)
- An Azure Subscription: [Free Account](https://azure.microsoft.com/en-gb/free/search/)
- An Azure DevOps Organization and Project: [Free Organization](https://aex.dev.azure.com/signup/)

### Installation

- Clone the repository locally and then follow the Demo / Lab.

### Quickstart

The instructions for this sample are in the form of a Lab. Follow along with them to get up and running.

## Demo / Lab

### Install the Microsoft DevLabs Terraform Task in your Azure DevOps Organisation
1. Navigate to [dev.azure.com](https://dev.azure.com).
1. Login and navigate to your organisation.
1. Click on the marketplace icon (shopping bag) in the top right of the screen and select `Browse Marketplace`.
1. Type `terraform` into the search bar and hit enter.
1. Find the task published by `Microsoft DevLabs` and click on it. ([Here is a shortcut to take you directly there](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks))
1. Click `Get if free`.
1. Select your organisation from the drop down list and click `Install`.
1. > NOTE: If you are not an organisation administator, you will need to click `Request` instead and then prompt your admin person to approve it.

### Generate a PAT (Personal Access Token) in Azure DevOps

1. Navigate to [dev.azure.com](https://dev.azure.com).
1. Login and select the `User Settings` icon in the top right and then `Personal access tokens`.
1. Click `New token`.
1. Type `Demo_OIDC` into the `Name` field.
1. Click `Show all scopes` down at the bottom of the dialog.
1. Check these scopes:
   1. `Agent Pools`: `Read & manage`
   1. `Build`: `Read & execute`
   1. `Code`: `Full`
   1. `Environment`: `Read & manage`
   1. `Service Connections`: `Read, query, & manage`
   1. `Project and Team`: `Read, write, & manage`
   1. `Variable Groups`: `Read, create, & manage`
1. Click `Create`
1. > IMPORTANT: Copy the token and save it somewhere.

### Clone the repo and setup your variables

1. Clone this repository to your local machine.
1. Open the repo in Visual Studio Code. (Hint: In a terminal you can open Visual Studio Code by navigating to the folder and running `code .`).
1. Navigate to the `bootstrap` folder and create a new file called `terraform.tfvars`.
1. In the `terraform.tfvars` file add the following:

    ```terraform
    postfix                   = "<your_initials>-<date_as_YYYYMMDD>"
    azure_devops_organization = "<your_azure_devops_organisation_name>"
    azure_devops_project      = "<your_azure_devops_project_name>"
    ```

    e.g.

    ```terraform
    postfix                   = "JFH-20221208"
    azure_devops_organization = "my-organization"
    azure_devops_project      = "my-project"
    ```

    If you wish to use Microsoft-hosted agents and public networking add this setting to `terraform.tfvars`:

    ```terraform
    use_self_hosted_agents = false
    ```

    If you wish to use Container Apps (scale to zero) add this setting to `terraform.tfvars`:

    >NOTE: Container App takes longer to provision than Container Instances.

    ```terraform
    self_hosted_agent_type = "azure_container_app"
    ```

### Apply the Terraform

1. Open the Visual Studio Code Terminal and navigate the `terraform-oidc-config` folder.
1. Run `az login` and follow the prompts to login to Azure with your Global Administrator account.
1. Run `az account show`. If you are not connected to you test subscription, change it by running `az account set --subscription "<subscription-id>"`
1. Run `$env:ARM_SUBSCRIPTION_ID = $(az account show --query id -o tsv)` to set the subscription id required by azurerm provider v4.
1. Run `terraform init`.
1. Run `terraform apply`.
1. You'll be prompted for the variable `var.azure_devops_token`. Paste in the PAT you generated earlier and hit enter.
1. The plan will complete. Review the plan and see what is going to be created.
1. Type `yes` and hit enter once you have reviewed the plan.
1. Wait for the apply to complete.
1. You will see three outputs from this run. These are the Service Principal Ids that you will require in the next step. Save them somewhere.

> NOTE: If you are a Microsoft employee you may get a 403 error here. If so, you need to grant your PAT SSO access to the Azure-Samples organisation. This does not affect non-Microsoft users.

### Check what has been created

#### Managed Identity or Service Principal

When deploying the example you will have selected to use the default Managed Identity approach or the Service Principal approach choose the relevant option below.

##### Managed Identity

1. Login to the [Azure Portal](https://portal.azure.com) with your Global Administrator account.
1. Navigate to your Subscription and select `Resource groups`.
1. Click the resource group post-fixed `identity` (e.g. `JFH-20221208-identity`).
1. Look for a `Managed Identity` resource post-fixed with `dev` and click it.

#### Federated Credentials
1. Click on `Federated Credentials`.
1. There should only be one credential in the list, select that and take a look at the configuration.
1. Examine the `Subject identifier` and ensure you understand how it is built up.

#### Resource Group and permissions

1. Navigate to your Subscription and select `Resource groups`.
1. You should see four newly created resource groups.
1. Click the resource group post-fixed `dev` (e.g. `rg-JFH-20221208-env-dev`).
1. Select `Access control (IAM)` and select `Role assignments`.
1. Under the `Reader` role, you should see that your `dev-plan` Managed Identity has been granted access directly to the resource group.
1. Under the `Contributor` role, you should see that your `dev-apply` Managed Identity has been granted access directly to the resource group.

#### State storage account

1. Navigate to your Subscription and select `Resource groups`.
1. Click the resource group post-fixed `state` (e.g. `JFH-20221208-state`).
1. You should see a single storage account in there, click on it.
1. Select `Containers`. You should see a `dev`, `test` and `prod` container.
1. Select the `dev` container.
1. Click `Access Control (IAM)` and select `Role assignments`.
1. Scroll down to `Storage Blob Data Owner`. You should see your `dev-plan` and `dev-apply` Managed Identities have been assigned that role.

#### Azure DevOps Repository

1. Open Azure DevOps in your browser (login if you need to).
1. Navigate to your organisation and project.
1. Click `Repos`, then select your new repo in the drop down at the top of the page (e.g. `JFH-20221208-demo`). Click on it.
1. You should see some files under source control.

#### Azure DevOps Environments

1. Hover over `Pipelines`, then select `Environments`.
1. You should see 3 environments called `dev`, `test` and `prod`.
1. Click on the `dev` environment and take a look at the settings.

#### Azure DevOps Variable Group

1. Hover over `Pipelines`, then select `Library`.
1. You should see 3 variable groups called `dev`, `test` and `prod`.
1. Click on the `dev` environment and take a look at the variables.

#### Azure DevOps Service Connections

1. Click `Project Settings` in the bottom left corner.
1. Click `Service connections` under the `Pipelines` section.
1. There should be 3 service connections configured for Managed Identity or Workload Identity Federation depending on the option you choose.
1. Click on one of the service connections and click `Edit` to look at the settings.

#### Option 3 Only: Azure DevOps Agent Pools

1. Click `Project Settings` in the bottom left corner.
1. Click `Agent pools` under the `Pipelines` section.
1. There should be 3 new agent pools configured.
1. Click on one of them and navigate to the `Agents` tab, you should see 2 agents in the pool ready to accept runs.

#### Azure DevOps Pipeline

1. Click on `Pipelines`
1. You should see a pipeline in the list. Click on it.
1. Click on `Edit` and examine the pipeline.

### Run the Pipeline

1. Select `Pipelines`, then click on the pipeline you created.
1. Click the `Run pipeline` in the top right, then click `Run` in the dialog.
1. Wait for the run to appear or refresh the screen, then click on the run to see the details.
1. You will see each environment being deployed one after the other. In a real world scenarios you may want to have a manual intervention on the environment for an approval to promote to the next stage.
1. You will also note that the `Validation` step was skipped.
1. Drill into the log for one of the environments and look at the `Terraform Apply` step. You should see the output of the plan and apply.
1. Run the workflow again and take a look at the log to compare what happens on the Day 2 run.

### Submit a PR
1. Clone your new repository and open it in Visual Studio Code.
1. Create a new branch, call it whatever you want.
1. Open the `terraform-example-deploy/virtual-machine.tf` file.
1. Rename the virtual machine to `example-machine-pr`.
1. Commit and push the change.
1. Raise a pull request.
1. You'll see the Azure DevOps Pipeline running in the pull request. This is because we created a branch policy to enforce this.
1. The `Terraform Fmt` step will fail for `main.tf`. Fix it, commit and push your change.
1. Wait for the Pipeline to run again.
1. Merge the Pull Request.
1. Navigate to `Pipelines` and watch the run.

## Resources

- [Terraform Steps for Azure DevOps](https://github.com/microsoft/azure-pipelines-terraform/blob/main/Tasks/TerraformTask/TerraformTaskV4/README.md))
- [Terraform azurerm provider OIDC configuration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc)
- [Azure DevOps OIDC Docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers)
- [Azure External Identity Docs](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp)
