#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Prepares Terraform azure provider environment variables
 
.EXAMPLE
    ./set_terraform_azurerm_vars
#> 
#Requires -Version 7.2

if ($env:SYSTEM_DEBUG -eq "true") {
    $InformationPreference = "Continue"
    $VerbosePreference = "Continue"
    $DebugPreference = "Continue"
    
    Get-ChildItem -Path Env: -Force -Recurse -Include * | Sort-Object -Property Name | Format-Table -AutoSize | Out-String
}

# Propagate Azure context to Terraform
az account show 2>$null | ConvertFrom-Json | Set-Variable account
if (!$account) {
    throw "Not logged into Azure CLI, no context to propagate as ARM_* environment variables"
}
if (![guid]::TryParse($account.user.name, [ref][guid]::Empty)) {
    throw "Azure CLI logged in with a User Principal instead of a Service Principal"
}
$env:ARM_CLIENT_ID       ??= $account.user.name
$env:ARM_CLIENT_SECRET   ??= $env:servicePrincipalKey # requires addSpnToEnvironment: true
$env:ARM_OIDC_TOKEN      ??= $env:idToken # requires addSpnToEnvironment: true
$env:ARM_SUBSCRIPTION_ID ??= $account.id  
$env:ARM_TENANT_ID       ??= $account.tenantId
$env:ARM_USE_CLI         ??= (!($env:idToken -or $env:servicePrincipalKey)).ToString().ToLower()
$env:ARM_USE_OIDC        ??= ($env:idToken -ne $null).ToString().ToLower()

if ($env:ARM_CLIENT_SECRET) {
    Write-Verbose "Using ARM_CLIENT_SECRET"
} elseif ($env:ARM_OIDC_TOKEN) {
    Write-Verbose "Using ARM_OIDC_TOKEN"
} else {
    Write-Warning "No credentials found to propagate as ARM_* environment variables. Using ARM_USE_CLI = true."
}
Write-Host "`nTerraform azure provider environment variables:" -NoNewline
Get-ChildItem -Path Env: -Recurse -Include ARM_* | ForEach-Object { 
                                                       if ($_.Name -match 'SECRET|TOKEN') {
                                                           $_.Value = "<redacted>"
                                                       } 
                                                       $_
                                                   } `
                                                 | Sort-Object -Property Name `
                                                 | Format-Table -HideTableHeader