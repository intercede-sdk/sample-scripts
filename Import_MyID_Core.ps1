<#
.DESCRIPTION
This script shows how a user can be imported using details from a CSV file.
A request is then made for the imported user.
If the user already exists, an error will be shown, but it is possible to create a request for an existing user by passing the CanUseExistingUser switch
#>
Param
(
    [Parameter(Mandatory)]
    [string]$ClientId,
    [Parameter(Mandatory)]
    [string]$ClientSecret,

    [string]$Server = "https://react.domain31.local",
    [string]$GroupName = "Technology",
    [string]$RoleName = "MyID_PROD_Cardholders",
    [string]$RoleScope = "self",
    [string]$Domain = "domain31",
    [string]$CredProfileName = "TMO_1",
    
    [switch]$CanUseExistingUser,
    [switch]$ShowLinks
)

Import-Module $PSScriptRoot\Invoke-CoreAPI.psm1 -Force

Set-CoreAPIConnection -Server $Server -ClientId $ClientId -ClientSecret $ClientSecret

################ Get Group
# Make sure group we are trying to set exists
# We could add group through API, but it seems more sensible that Config should be done ahead
$groupId = (Invoke-CoreAPIGet -Location "groups?q=$GroupName" -FailureMessage "Unable to get group").results.id
if (!$groupId) {
    return "Unable to find Group '$GroupName'"
}

################ Get Role
# Make sure role we are trying to set exists
# Unfortunately this API endpoint doesn't filter on name
$roleId = (Invoke-CoreAPIGet -Location "roles" -FailureMessage "Unable to get role").results | Where-Object id -eq $RoleName
if (!$roleId) {
    return "Unable to find Role '$RoleName'"
}

################ Add/Get User
Import-CSV -Path .\ACastle2.csv -Delimiter ';' |
ForEach-Object {
    $logonName = $_.SAMAccountName
    $body = @{
        name      = @{
            first = $_.GivenName
            last  = $_.sn
        }
        enabled   = 1
        logonName = $logonName
        group     = @{
            id   = $groupId
            name = $GroupName
        }
        roles     = @(
            @{
                id    = $RoleName
                name  = $RoleName
                scope = $RoleScope
            }
        )
        account   = @{
            samAccountName = $logonName
            upn            = $_.userPrincipalName
            dn             = $_.distinguishedName
            cn             = $_.CN
            domain         = $Domain

        }
    }
}

if ($CanUseExistingUser) {
    $userId = (Invoke-CoreAPIGet -Location "people?logonName=$logonName").results.id
}

if (!$userId) {
    $userId = (Invoke-CoreAPIPost -Location "people" -FailureMessage "Unable to add user" -Body $body).id
    if (!$userId) {
        return
    }
}

################ Create request
$credProfileId = (Invoke-CoreAPIGet -Location "credprofiles?q=$CredProfileName" -FailureMessage "Unable to get credential profile").results.id
if (!$credProfileId) {
    return "Unable to find Credential profile '$CredProfileName'"
}

$body = @{
    credProfile = @{
        id = $credProfileId
    }
}

$response = Invoke-CoreAPIPost -Location "people/$userId/requests" -FailureMessage "Unable to create request for user" -Body $body
if ($response) {
    "Request created for user."

    if (!$ShowLinks) {
        $response.PSObject.Properties.Remove('links')
    }
    ConvertTo-Json $response -Depth 6
}
