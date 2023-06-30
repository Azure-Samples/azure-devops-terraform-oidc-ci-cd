param (
    [string]$action = "Create",
    [string]$serviceConnectionType = "OIDC",
    [string]$serviceConnectionName,
    [string]$clientId = "",
    [string]$tenantId,
    [string]$subscriptionId,
    [string]$subscriptionName,
    [string]$projectId,
    [string]$projectName,
    [string]$accessToken,
    [string]$organizationUrl,
    [string]$apiVersion = "7.1-preview.4"
)

Write-Host "Action: ${action}"

# Setup Authorization Header
$base64PatToken = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("`:$accessToken"))

$headers=@{
    "Authorization" = "Basic $base64PatToken"
}

# Check Service Connection Exists
$apiUri = "${organizationUrl}/${projectName}/_apis/serviceendpoint/endpoints?endpointNames=${serviceConnectionName}&api-version=${apiVersion}"

Invoke-RestMethod -Uri $apiUri `
                  -Method 'GET' `
                  -ContentType 'application/json' `
                  -Headers $headers `
                  | Set-Variable serviceEndpoints

if ($serviceEndpoints.count -gt 0) {
    Write-Host "Service connection '${serviceConnectionName}' already exists."
    $serviceConnectionExists = $true
    $serviceConnectionId = $serviceEndpoints.value[0].id
}

if($serviceConnectionExists -and $action -eq "Destroy") {
    Write-Host "Deleting service connection '${serviceConnectionName}'."
    $apiUri = "${organizationUrl}/_apis/serviceendpoint/endpoints/${serviceConnectionId}?projectIds=${projectId}&api-version=${apiVersion}"

    $apiUri | Write-Host

    Invoke-RestMethod -Uri $apiUri `
                    -Method 'DELETE' `
                    -ContentType 'application/json' `
                    -Headers $headers `
                    | Set-Variable serviceEndpoint
}

if ($serviceConnectionExists -or $action -eq "Destroy") {
    return
}

# Prepare service connection REST API request body
Write-Host "Creating / updating service connection '${serviceConnectionName}'..."
Get-Content -Path (Join-Path $PSScriptRoot "serviceEndpointRequest${serviceConnectionType}.json") `
            | ConvertFrom-Json `
            | Set-Variable serviceEndpointRequest

$serviceEndpointDescription = $serviceConnectionName
if($serviceConnectionType -eq "OIDC") {
    $serviceEndpointRequest.authorization.parameters.servicePrincipalId = $clientId
}
$serviceEndpointRequest.authorization.parameters.tenantId = $tenantId
$serviceEndpointRequest.data.subscriptionId = $subscriptionId
$serviceEndpointRequest.data.subscriptionName = $subscriptionName
$serviceEndpointRequest.description = $serviceEndpointDescription
$serviceEndpointRequest.name = $serviceConnectionName
$serviceEndpointRequest.serviceEndpointProjectReferences[0].description = $serviceEndpointDescription
$serviceEndpointRequest.serviceEndpointProjectReferences[0].name = $serviceConnectionName
$serviceEndpointRequest.serviceEndpointProjectReferences[0].projectReference.id = $projectId
$serviceEndpointRequest.serviceEndpointProjectReferences[0].projectReference.name = $projectName
$serviceEndpointRequest | ConvertTo-Json -Depth 4 | Set-Variable serviceEndpointRequestBody

$apiUri = "${organizationUrl}/_apis/serviceendpoint/endpoints?api-version=${apiVersion}"

Invoke-RestMethod -Uri $apiUri `
                  -Method 'POST' `
                  -Body $serviceEndpointRequestBody `
                  -ContentType 'application/json' `
                  -Headers $headers `
                  | Set-Variable serviceEndpoint

$serviceEndpoint | ConvertTo-Json -Depth 4 | Write-Host
if (!$serviceEndpoint) {
    Write-Error "Failed to create / update service connection '${serviceConnectionName}'"
    exit 1
}

Write-Host "Service connection '${serviceConnectionName}' created:"