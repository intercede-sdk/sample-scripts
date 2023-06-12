<#
.SYNOPSIS
Add or update shared secret authentication node

.DESCRIPTION
Updates the appsettings.production.json configuration file from the web.oauth2 service to include a shared secret authentication entry.
Copy the existing appsettings.production.json configuration file to the folder containing this script before running.
After running, the updated appsettings.production.json configuration file can be copied to the MyID server.
Always make backups, and confirm that changes are as expected.
Note that newer versions of PowerShell are able to better handle poorly formatted JSON in appsettings.production.json.


.PARAMETER ClientId
The client identifier, e.g. myid.mysystem

.PARAMETER ClientSecret
The client secret, e.g. efdc4478-4fda-468b-9d9a-78792c20c683
If not set, a new client secret is generated. *IMPORTANT*: keep a record of this secret in a safe place.

.PARAMETER MyIDLogonName
The LogonName of an existing MyID user that defines how the client will access MyID

.PARAMETER ClientName
The client readable name, e.g. "My External System"

.EXAMPLE
.\Configure_OAuth.ps1 -ClientId myid.mysystem -MyIDLogonName api.external
Using client secret: e96f1e8c-7c03-4e61-bb16-05637c3d5069, with client identifier: myid.mysystem
'myid.mysystem' client not found, adding it

.EXAMPLE
.\Configure_OAuth.ps1 -ClientId myid.mysystem -MyIDLogonName api.external -ClientSecret efdc4478-4fda-468b-9d9a-78792c20c683
Using client secret: efdc4478-4fda-468b-9d9a-78792c20c683, with client identifier: myid.mysystem
'myid.mysystem' client already exists, updating it

.EXAMPLE
.\Configure_OAuth.ps1
cmdlet Configure_OAuth.ps1 at command pipeline position 1
Supply values for the following parameters:
ClientId: myid.mysystem
MyIDLogonName: Homer Peggs
'myid.mysystem' client already exists, updating it
Client identifier: myid.mysystem
Client secret: 21f52369-b497-428a-a68c-a9f08711922a
#>

[CmdletBinding(PositionalBinding = $false)]
Param
(
    [Parameter(Mandatory)]
    [string]$ClientId,
    [Parameter(Mandatory)]
    [string]$MyIDLogonName,

    [string]$ClientName = "My External System",
    [string]$ClientSecret
)

Import-Module $PSScriptRoot\ConfigureSettings.psm1 -Force

if (!$ClientSecret) {
    $ClientSecret = (New-Guid).ToString()
}

# Hash the GUID using SHA-256, and convert to Base64
$hasher = [System.Security.Cryptography.HashAlgorithm]::Create("sha256")
$hashOfSecret = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($ClientSecret))
$base64Secret = [Convert]::ToBase64String($hashOfSecret)

$authConfigPath = ".\appsettings.production.json"

if(-Not(Test-Path $authConfigPath)) {
 return "appsettings.production.json not found. Make necessary changes manually:
 client secret: $clientSecret
 Hash: $base64Secret"
}

$authConfig = Read-JSON $authConfigPath

$existingClient = ($authConfig.Clients | Where-Object { $_.ClientId -eq $ClientId })

if ($null -eq $existingClient) {
    Write-Host "'$ClientId' client not found, adding it"

    $clientString =
    @"
    {
        "ClientId": "$ClientId",
        "ClientName": "$ClientName",
        "ClientSecrets": [
            {
                "Value": "$base64Secret"
            }
        ],
        "AllowedGrantTypes": [
            "client_credentials"
        ],
        "AllowedScopes": [
            "myid.rest.basic"
        ],
        "Properties": {
            "MyIDLogonName": "$MyIDLogonName"
        }
    }
"@    

    $authConfig.Clients += (ConvertFrom-Json $clientString)
}
else {
    Write-Host "'$ClientId' client already exists, updating it"
    $existingClient.ClientName = $ClientName
    $existingClient.ClientSecrets[0].Value = $base64Secret
    $existingClient.Properties.MyIDLogonName = $MyIDLogonName
}

Write-Host "Client identifier: $ClientId
Client secret: $ClientSecret"

Write-Json $authConfig $authConfigPath